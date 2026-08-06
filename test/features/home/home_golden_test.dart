@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';
import 'package:medix/shared/models/doctor_specialty.dart';
import 'package:medix/features/home/presentation/providers/home_providers.dart';
import 'package:medix/features/home/presentation/screens/home_screen.dart';

import '../../helpers/test_fonts.dart';

/// Эталон главной для сверки с `design/Главная.png`.
///
/// Рендерим в высоту макета (1299), а не устройства: страница прокручиваемая,
/// и только так видно все блоки сразу и можно сравнить их позиции с макетом.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('home_screen соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 1299);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Синхронно, а не через MockHomeRepository: та отдаёт данные через
          // Future.delayed, таймер создаётся вне runAsync и тест падает
          // на «timersPending».
          specialtiesProvider.overrideWith((ref) => _specialties),
          upcomingAppointmentsProvider.overrideWith((ref) => _appointments),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
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

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_screen.png'),
    );
  });
}

/// Те же данные, что на макете.
const _specialties = [
  DoctorSpecialty(id: 'therapist', title: 'Терапевт', doctorCount: 100),
  DoctorSpecialty(id: 'pediatrician', title: 'Педиатр', doctorCount: 100),
  DoctorSpecialty(id: 'cardiologist', title: 'Кардиолог', doctorCount: 48),
];

final _appointments = [
  Appointment(
    id: 'a1',
    specialty: 'Кардиолог',
    kind: AppointmentKind.videoCall,
    startsAt: DateTime(2026, 8, 13, 10, 30),
  ),
  Appointment(
    id: 'a2',
    specialty: 'Кардиолог',
    kind: AppointmentKind.videoCall,
    startsAt: DateTime(2026, 8, 13, 15),
  ),
];
