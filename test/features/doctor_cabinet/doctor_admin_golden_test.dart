@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_answer_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_request_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_requests_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны заявки в администрацию — сверка с
/// `design/для врача от клиники/Запросы к админу.png`, `.../Мои заявки.png`
/// и `.../Ответ от админа.png` (все 440×956).
///
/// Состояние с набранным текстом эталоном не закрывается: там курсор и
/// дата «сегодня», то есть картинка менялась бы каждый день.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
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
          home: screen,
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
  }

  testWidgets('doctor_admin_topics_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(tester, const DoctorAdminRequestScreen());

    await expectLater(
      find.byType(DoctorAdminRequestScreen),
      matchesGoldenFile('goldens/doctor_admin_topics_screen.png'),
    );
  });

  testWidgets('doctor_admin_requests_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(tester, const DoctorAdminRequestsScreen());

    await expectLater(
      find.byType(DoctorAdminRequestsScreen),
      matchesGoldenFile('goldens/doctor_admin_requests_screen.png'),
    );
  });

  testWidgets('doctor_admin_answer_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(tester, const DoctorAdminAnswerScreen(requestId: 'ar1'));

    await expectLater(
      find.byType(DoctorAdminAnswerScreen),
      matchesGoldenFile('goldens/doctor_admin_answer_screen.png'),
    );
  });
}
