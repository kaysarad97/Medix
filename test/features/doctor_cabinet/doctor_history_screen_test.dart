import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_history_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
          ),
          selectedHistoryDayProvider.overrideWith(
            () => _FixedDay(DateTime(2026, 7, 21)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует месяц, предыдущую запись и список других', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('История записей'), findsOneWidget);
    expect(find.text('Июль, 2026'), findsOneWidget);
    expect(find.text('Предыдущая запись'), findsOneWidget);
    expect(find.text('Другие записи'), findsOneWidget);
    // Фейк отдаёт две записи, и обе — аудио-звонки: одна в выделенной
    // карточке, две в списке.
    expect(find.text('Аудио-звонок'), findsNWidgets(3));
    expect(find.text('с Имя Фамилия'), findsNWidgets(3));
  });

  testWidgets('поиск по имени убирает непопавшие записи', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'Петров');
    await tester.pump();
    await tester.pump();

    // Список «Других записей» опустел, а выделенная карточка предыдущей
    // записи поиску не подчиняется — она про другой период.
    expect(find.text('Записей пока нет'), findsOneWidget);
  });

  testWidgets('стрелка пейджера листает неделю назад', (tester) async {
    await pumpScreen(tester);

    expect(find.text('14.07-20.07'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left).last);
    await tester.pump();
    await tester.pump();

    expect(find.text('07.07-13.07'), findsOneWidget);
  });
}

class _FixedDay extends SelectedHistoryDay {
  _FixedDay(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
