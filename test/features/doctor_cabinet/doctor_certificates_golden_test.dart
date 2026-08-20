@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/certificate.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_certificates_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Ваши сертификаты» — сверка с
/// `design/для врача от клиники/Сертификаты -  в.ф.png` (440×956, шесть
/// карточек умещаются на экран без прокрутки).
void main() {
  setUpAll(loadAppFonts);

  testWidgets('doctor_certificates_screen соответствует эталону', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCertificatesProvider.overrideWith(
            (ref) => const [
              Certificate(id: 'c1', fileName: 'Документ 1.pdf'),
              Certificate(id: 'c2', fileName: 'Документ 2.pdf'),
              Certificate(id: 'c3', fileName: 'Документ 3.pdf'),
              Certificate(id: 'c4', fileName: 'Документ 4.pdf'),
              Certificate(id: 'c5', fileName: 'Документ 5.pdf'),
              Certificate(id: 'c6', fileName: 'Документ 6.pdf'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorCertificatesScreen(),
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
      find.byType(DoctorCertificatesScreen),
      matchesGoldenFile('goldens/doctor_certificates_screen.png'),
    );
  });
}
