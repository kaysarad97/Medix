import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/procedures_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProceduresScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  group('предыдущие процедуры', () {
    testWidgets('показывает мои процедуры по умолчанию', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Предыдущие процедуры'), findsOneWidget);
      expect(find.text('Пульмонолог'), findsOneWidget);
      expect(
        find.text('Было найдено 6 процедур в Вашей мед-карте'),
        findsOneWidget,
      );
      // Процедуры ребёнка на вкладке «Мои процедуры» не видны.
      expect(find.text('Педиатр'), findsNothing);
    });

    testWidgets('вкладка «Процедуры ребёнка» показывает только их', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Процедуры ребёнка'));
      await tester.pump();

      expect(find.text('Педиатр'), findsOneWidget);
      expect(find.text('Пульмонолог'), findsNothing);
    });

    testWidgets('поиск отфильтровывает по специальности', (tester) async {
      await pumpScreen(tester);

      // Строчными: чтобы найденная строка «ЛОР» не совпала с введённым
      // текстом в самом поле поиска (фильтр регистронезависимый).
      await tester.enterText(find.byType(TextField), 'лор');
      await tester.pump();

      expect(find.text('ЛОР'), findsOneWidget);
      expect(find.text('Пульмонолог'), findsNothing);
    });

    testWidgets('нажатие на строку показывает снек-бар', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Пульмонолог'));
      await tester.pump();

      expect(
        find.text('Экран с результатами процедуры ещё не готов'),
        findsOneWidget,
      );
    });
  });
}
