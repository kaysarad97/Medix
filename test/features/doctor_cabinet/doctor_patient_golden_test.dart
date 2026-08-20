@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_appointment_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны «Профиля пациента» и «Записи с пациентом» — сверка с
/// `design/для врача от клиники/Профиль пациента.png` (440×1438, страница
/// прокручиваемая) и `.../Запись с пациентом.png` (440×978).
///
/// Высота эталона профиля пациента взята по содержимому, а не макетная:
/// в макете ниже анализов только артефакт таб-бара.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
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

  testWidgets('doctor_patient_screen соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      const DoctorPatientScreen(patientId: 'p1'),
      const Size(440, 1200),
    );

    await expectLater(
      find.byType(DoctorPatientScreen),
      matchesGoldenFile('goldens/doctor_patient_screen.png'),
    );
  });

  testWidgets('doctor_patient_appointment_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const DoctorPatientAppointmentScreen(patientId: 'p1'),
      const Size(440, 978),
    );

    await expectLater(
      find.byType(DoctorPatientAppointmentScreen),
      matchesGoldenFile('goldens/doctor_patient_appointment_screen.png'),
    );
  });
}
