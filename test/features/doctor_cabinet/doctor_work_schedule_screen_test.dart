import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_work_slot.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_work_schedule_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_schedule_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  final fixedDay = DateTime(2026, 8, 21);

  Future<FakeDoctorScheduleRepository> pumpScreen(
    WidgetTester tester, {
    List<DoctorWorkSlot> initial = const [],
  }) async {
    final repository = FakeDoctorScheduleRepository(initial: initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorScheduleRepositoryProvider.overrideWithValue(repository),
          selectedWorkScheduleDayProvider.overrideWith(
            () => _FixedDay(fixedDay),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorWorkScheduleScreen(now: () => DateTime(2026, 8, 21, 9)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repository;
  }

  testWidgets('пустой день подписан текстом-заглушкой', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Рабочие часы'), findsOneWidget);
    expect(find.text('На этот день слотов нет'), findsOneWidget);
  });

  testWidgets('рисует слоты с временем и статусом', (tester) async {
    await pumpScreen(
      tester,
      initial: [
        DoctorWorkSlot(
          id: 's1',
          doctorId: 'd1',
          startsAt: DateTime(2026, 8, 21, 10),
          endsAt: DateTime(2026, 8, 21, 10, 30),
          status: DoctorWorkSlotStatus.open,
        ),
        DoctorWorkSlot(
          id: 's2',
          doctorId: 'd1',
          startsAt: DateTime(2026, 8, 21, 11),
          endsAt: DateTime(2026, 8, 21, 11, 30),
          status: DoctorWorkSlotStatus.booked,
        ),
      ],
    );

    expect(find.text('10:00–10:30'), findsOneWidget);
    expect(find.text('Свободно'), findsOneWidget);
    expect(find.text('11:00–11:30'), findsOneWidget);
    expect(find.text('Занято'), findsOneWidget);
    // Крестик удаления — только у свободного слота.
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('крестик удаляет свободный слот', (tester) async {
    final repository = await pumpScreen(
      tester,
      initial: [
        DoctorWorkSlot(
          id: 's1',
          doctorId: 'd1',
          startsAt: DateTime(2026, 8, 21, 10),
          endsAt: DateTime(2026, 8, 21, 10, 30),
          status: DoctorWorkSlotStatus.open,
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump();

    expect(find.text('10:00–10:30'), findsNothing);
    expect(
      await repository.schedule(
        from: fixedDay,
        to: fixedDay.add(const Duration(days: 1)),
      ),
      isEmpty,
    );
  });

  testWidgets('добавление слота через шторку доходит до списка', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Добавить слот'));
    await tester.pumpAndSettle();

    expect(find.text('Новый слот'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    // Шторка закрылась, слот появился в списке со временем по умолчанию
    // от фиксированного «сейчас» — 09:00 (час) → 10:00 (час + 1).
    expect(find.text('На этот день слотов нет'), findsNothing);
    expect(find.text('09:00–10:00'), findsOneWidget);
    expect(find.text('Свободно'), findsOneWidget);
  });
}

class _FixedDay extends SelectedWorkScheduleDay {
  _FixedDay(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
