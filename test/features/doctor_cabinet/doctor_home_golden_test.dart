@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/regular_patient.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_home_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон главной кабинета врача — сверка с
/// `design/для врача от клиники/Главная - в.ф.png` (440×1330).
void main() {
  setUpAll(loadAppFonts);

  testWidgets('doctor_home_screen соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 1330);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorUpcomingAppointmentsProvider.overrideWith(
            (ref) => [
              DoctorAppointment(
                id: 'a1',
                patientName: 'Пациент Имя Фамилия',
                kind: AppointmentKind.videoCall,
                startsAt: DateTime(2026, 8, 13, 10, 30),
              ),
              DoctorAppointment(
                id: 'a2',
                patientName: 'Пациент Имя Фамилия',
                kind: AppointmentKind.videoCall,
                startsAt: DateTime(2026, 8, 13, 15),
              ),
            ],
          ),
          doctorRegularPatientsProvider.overrideWith(
            (ref) => const [
              RegularPatient(id: 'p1', fullName: 'Ф. Имя Отчество'),
              RegularPatient(id: 'p2', fullName: 'Ф. Имя Отчество'),
              RegularPatient(id: 'p3', fullName: 'Ф. Имя Отчество'),
              RegularPatient(id: 'p4', fullName: 'Ф. Имя Отчество'),
            ],
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorHomeScreen(),
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
      find.byType(DoctorHomeScreen),
      matchesGoldenFile('goldens/doctor_home_screen.png'),
    );
  });
}
