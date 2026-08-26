@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_settings_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Настройки» — сверка с
/// `design/для врача от клиники/Настройки Врач.png` (клиника) и
/// `design/врач фрилансер/Настройки Врач.png` (фрилансер).
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool showFreelancerRows = false,
  }) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorSettingsScreen(showFreelancerRows: showFreelancerRows),
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

  testWidgets('doctor_settings_screen соответствует эталону', (tester) async {
    await pumpScreen(tester);

    await expectLater(
      find.byType(DoctorSettingsScreen),
      matchesGoldenFile('goldens/doctor_settings_screen.png'),
    );
  });

  testWidgets('doctor_settings_screen (фрилансер) соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(tester, showFreelancerRows: true);

    await expectLater(
      find.byType(DoctorSettingsScreen),
      matchesGoldenFile('goldens/doctor_settings_screen_freelancer.png'),
    );
  });
}
