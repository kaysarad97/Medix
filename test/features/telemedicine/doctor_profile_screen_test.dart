import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/doctor_profile_screen.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpProfile(WidgetTester tester) async {
    // Макет 440×956 — гоняем тест в тех же размерах, что и дизайн.
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DoctorProfileScreen(doctorId: 'd1'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('рисует шапку врача из макета «Профиль врача + запись»', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('О враче'), findsOneWidget);
    expect(find.text('Алматы'), findsOneWidget);
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('Гастроэнтеролог'), findsOneWidget);
    expect(find.text('Название клиники, улица, город'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Стаж 10 лет'), findsOneWidget);
  });

  testWidgets('рисует расписание и отзывы', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Июль, 2026'), findsOneWidget);
    expect(find.text('Топ отзывов'), findsOneWidget);
    expect(find.text('Пользователь 1'), findsOneWidget);
    expect(find.text('Оставьте свой отзыв...'), findsOneWidget);
  });

  testWidgets('при открытии выбран первый доступный день и его первое время', (
    tester,
  ) async {
    await pumpProfile(tester);

    // Неделя из заглушки — 20…26 июля, выходные заняты.
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('9:30'), findsOneWidget);
    expect(find.text('15:30'), findsOneWidget);
  });

  testWidgets('час в слоте без ведущего нуля', (tester) async {
    await pumpProfile(tester);

    expect(find.text('9:30'), findsOneWidget);
    expect(find.text('09:30'), findsNothing);
  });

  testWidgets('переключение дня сбрасывает выбранное время', (tester) async {
    await pumpProfile(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoctorProfileScreen)),
    );
    final notifier = container.read(scheduleSelectionProvider.notifier);
    final schedule = await container.read(doctorScheduleProvider('d1').future);

    notifier.selectSlot(schedule.days.first.slots.last);
    expect(container.read(scheduleSelectionProvider).slot, isNotNull);

    notifier.selectDay(schedule.days[1]);
    expect(container.read(scheduleSelectionProvider).slot, isNull);
    expect(
      container.read(scheduleSelectionProvider).resolve(schedule).slot,
      schedule.days[1].slots.first,
    );
  });

  testWidgets('выходной день выбрать нельзя', (tester) async {
    await pumpProfile(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoctorProfileScreen)),
    );
    final notifier = container.read(scheduleSelectionProvider.notifier);
    final schedule = await container.read(doctorScheduleProvider('d1').future);

    final saturday = schedule.days[5];
    expect(saturday.isAvailable, isFalse);

    notifier.selectDay(saturday);
    expect(container.read(scheduleSelectionProvider).day, isNull);
  });
}
