import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_calendar_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) {
    return tester.pumpWidget(
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
          home: const DoctorCalendarScreen(),
        ),
      ),
    );
  }

  testWidgets('раскладывает записи по корзинам и подписывает пустую', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Утренние записи'), findsOneWidget);
    expect(find.text('Дневные записи'), findsOneWidget);
    expect(find.text('Вечерние записи'), findsOneWidget);
    // Фейк отдаёт 10:30 и 11:30 (утро), 14:30 и 15:30 (день), вечер пуст.
    expect(find.text('Имя Фамилия'), findsNWidgets(4));
    expect(find.text('Записей пока нет'), findsOneWidget);
  });

  testWidgets('тап по будню в полосе дней меняет выбранный день', (
    tester,
  ) async {
    // Понедельник — фиксированный день недели, вторник рядом всегда будний,
    // тест не зависит от того, какой сегодня день на машине, где он идёт.
    final monday = DateTime(2026, 8, 17);
    expect(monday.weekday, DateTime.monday);
    final tuesday = monday.add(const Duration(days: 1));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
          ),
          selectedCalendarDayProvider.overrideWith(() => _FixedDay(monday)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorCalendarScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DoctorCalendarScreen)),
    );

    await tester.tap(find.text('${tuesday.day}'));
    await tester.pump();

    final after = container.read(selectedCalendarDayProvider);
    expect(after.day, tuesday.day);
  });
}

/// Стартует с заданного дня вместо «сегодня» — тест должен быть
/// детерминированным, а не зависеть от даты на машине, где он идёт.
class _FixedDay extends SelectedCalendarDay {
  _FixedDay(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
