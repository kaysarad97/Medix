import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/appointment_screen.dart';
import 'package:medix/features/telemedicine/presentation/screens/doctor_profile_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Проверки на реальных размерах устройств, а не только на размере макета.
///
/// Опасное место этих экранов — недельная лента расписания: семь колонок по
/// 40 с зазором 13 занимают 358 при внутренней ширине карточки 362. На
/// 360-точечном экране места нет, и лента обязана уменьшаться целиком, а не
/// вылезать за карточку.
void main() {
  setUpAll(loadAppFonts);

  const sizes = <String, Size>{
    'макет 440×956': Size(440, 956),
    'Galaxy S23 FE 393×830': Size(393, 830),
    'узкий 360×740': Size(360, 740),
  };

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
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
    await tester.pump();
    await tester.pump();
  }

  for (final entry in sizes.entries) {
    testWidgets('профиль врача: вёрстка не разъезжается, ${entry.key}', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const DoctorProfileScreen(doctorId: 'd1'),
        entry.value,
      );

      expect(tester.takeException(), isNull);

      // Лента дней целиком внутри экрана.
      final monday = tester.getRect(find.text('Пн'));
      final sunday = tester.getRect(find.text('Вс'));
      expect(monday.left, greaterThanOrEqualTo(0));
      expect(sunday.right, lessThanOrEqualTo(entry.value.width));

      // Строка со временем — тоже.
      final firstSlot = tester.getRect(find.text('9:30'));
      final lastSlot = tester.getRect(find.text('15:30'));
      expect(firstSlot.left, greaterThanOrEqualTo(0));
      expect(lastSlot.right, lessThanOrEqualTo(entry.value.width));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ваша запись: вёрстка не разъезжается, ${entry.key}', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const AppointmentScreen(appointmentId: 'a1'),
        entry.value,
      );

      expect(tester.takeException(), isNull);

      final date = tester.getRect(find.text('10.07, 13:30'));
      expect(date.right, lessThanOrEqualTo(entry.value.width));

      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('на ширине макета колонка дня остаётся 40 в ширину', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const DoctorProfileScreen(doctorId: 'd1'),
      const Size(440, 956),
    );

    // Шаг между понедельником и вторником — 53 по макету.
    final monday = tester.getRect(find.text('Пн'));
    final tuesday = tester.getRect(find.text('Вт'));
    expect(tuesday.center.dx - monday.center.dx, closeTo(53, 1));
  });
}
