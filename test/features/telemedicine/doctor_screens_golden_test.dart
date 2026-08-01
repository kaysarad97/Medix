@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/appointment_screen.dart';
import 'package:medix/features/telemedicine/presentation/screens/doctor_profile_screen.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны экранов врача для сверки с `design/Профиль врача + запись.png`
/// и `design/Ваша Запись.png`.
///
/// Рендерим в высоту макета, а не устройства: обе страницы прокручиваемые,
/// и только так видно все блоки сразу.
///
/// РАСХОЖДЕНИЯ С МАКЕТОМ, ОСОЗНАННЫЕ — их видно при сверке глазами:
///  • числа в ленте 20…26, а не 18…24: 18 июля 2026 — суббота, недели из
///    макета не существует (см. MockDoctorsRepository.mockWeek);
///  • выбран первый доступный день и его первое время, а в макете — Чт и
///    10:30, то есть произвольная иллюстрация;
///  • иконки — пустые кружки, пока дизайнер не отдал SVG (см. MedixIcons).
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
          // Синхронно, а не через MockDoctorsRepository: та отдаёт данные
          // через Future.delayed, таймер создаётся вне runAsync и тест
          // падает на «timersPending».
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: screen),
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
  }

  testWidgets('doctor_profile соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      const DoctorProfileScreen(doctorId: 'd1'),
      const Size(440, 1010),
    );

    await expectLater(
      find.byType(DoctorProfileScreen),
      matchesGoldenFile('goldens/doctor_profile.png'),
    );
  });

  testWidgets('appointment соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      const AppointmentScreen(appointmentId: 'a1'),
      const Size(440, 978),
    );

    await expectLater(
      find.byType(AppointmentScreen),
      matchesGoldenFile('goldens/appointment.png'),
    );
  });
}
