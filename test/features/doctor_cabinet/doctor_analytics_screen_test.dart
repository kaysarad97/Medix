import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_analytics_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/widgets/doctor_week_bar_chart.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
    // Экран длиннее телефона: на маленьком по умолчанию окне часть карточек
    // не строится, и проверять было бы нечего.
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
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
          home: const DoctorAnalyticsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует показатели недели и месяца', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Аналитика Работы'), findsOneWidget);
    expect(find.text('Записи за эту неделю'), findsOneWidget);
    expect(find.text('Аналитика недели'), findsOneWidget);
    expect(find.text('Аналитика месяца'), findsOneWidget);

    expect(find.text('7 записей'), findsOneWidget);
    expect(find.text('на 2 больше\nчем обычно'), findsOneWidget);
    expect(find.text('49 минут'), findsOneWidget);
    expect(find.text('+0.5'), findsOneWidget);
    expect(find.text('+20%'), findsOneWidget);

    expect(find.text('15 записей'), findsOneWidget);
    expect(find.text('46 минут'), findsOneWidget);
    expect(find.text('+1.5'), findsOneWidget);
    expect(find.text('+23%'), findsOneWidget);
  });

  testWidgets('пейджеры подписаны неделей и месяцем', (tester) async {
    await pumpScreen(tester);

    expect(find.text('13.07-19.07'), findsOneWidget);
    // В карточке месяца запятой нет, в отличие от «Истории записей».
    expect(find.text('Июль 2026'), findsOneWidget);
  });

  testWidgets('столбики подписаны днями недели и числами записей', (
    tester,
  ) async {
    await pumpScreen(tester);

    for (final label in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      expect(find.text(label), findsOneWidget);
    }
    // Значения ищем внутри графика: те же цифры стоят подписями оси у
    // ломаной за месяц, и по всему экрану их больше.
    Finder inChart(String text) => find.descendant(
      of: find.byType(DoctorWeekBarChart),
      matching: find.text(text),
    );
    // Столбики: 0, 2, 3, 1, 1 и два выходных без подписи.
    expect(inChart('3'), findsOneWidget);
    expect(inChart('1'), findsNWidgets(2));
    expect(inChart('0'), findsOneWidget);
  });
}
