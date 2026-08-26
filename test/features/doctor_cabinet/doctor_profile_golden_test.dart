@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_profile_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Ваш Профиль» — сверка с
/// `design/для врача от клиники/Профиль -  в.ф.png`. Высота 1200 — с
/// запасом на всё содержимое (около 1188 по расчёту), страница
/// прокручиваемая и без запаса эталон обрезал бы «Запросы в
/// администрацию» снизу.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('doctor_profile_screen соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorOwnProfileScreen(),
        ),
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
    await precacheScreenImages(tester);

    await expectLater(
      find.byType(DoctorOwnProfileScreen),
      matchesGoldenFile('goldens/doctor_profile_screen.png'),
    );
  });
}
