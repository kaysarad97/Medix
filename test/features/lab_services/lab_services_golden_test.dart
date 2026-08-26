@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_services_providers.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_services_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_lab_services_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Перечня услуг» — сверка с `design/Перечень услуг.png` (440×956).
void main() {
  setUpAll(loadAppFonts);

  testWidgets('lab_services соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labServicesRepositoryProvider.overrideWithValue(
            const FakeLabServicesRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LabServicesScreen(),
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
      find.byType(LabServicesScreen),
      matchesGoldenFile('goldens/lab_services.png'),
    );
  });
}
