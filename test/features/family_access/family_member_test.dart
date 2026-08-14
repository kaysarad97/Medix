import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<FakeFamilyRepository> pumpScreen(
    WidgetTester tester,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    final repository = FakeFamilyRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [familyRepositoryProvider.overrideWithValue(repository)],
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
    return repository;
  }

  /// Кнопка удаления — в самом низу длинного экрана, до неё надо доскроллить.
  Future<void> tapDelete(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Удалить профиль'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Удалить профиль'));
    await tester.pumpAndSettle();
  }

  group('карточка ребёнка', () {
    final screen = FamilyMemberScreen(
      memberId: 'f1',
      now: DateTime(2026, 8, 6),
    );

    testWidgets('рисует шапку, мед-карту и врачей', (tester) async {
      await pumpScreen(tester, screen);

      expect(find.text('Профиль ребёнка'), findsOneWidget);
      expect(find.text('мужчина'), findsOneWidget);
      expect(find.text('7/10/2020'), findsOneWidget);
      expect(find.text('5 лет'), findsOneWidget);
      expect(find.text('106 см'), findsOneWidget);
      expect(find.text('Родство с Вами'), findsOneWidget);
      expect(find.text('Врачи моего ребёнка'), findsOneWidget);
      expect(find.text('Педиатр'), findsOneWidget);
      expect(find.text('Анализы ребёнка'), findsOneWidget);
    });
  });

  group('карточка старших', () {
    final screen = FamilyMemberScreen(
      memberId: 'f2',
      now: DateTime(2026, 8, 6),
    );

    testWidgets('заголовки завязаны на имя, а не на «ребёнка»', (tester) async {
      await pumpScreen(tester, screen);

      expect(find.text('Профиль родителя'), findsOneWidget);
      expect(find.text('женщина'), findsOneWidget);
      expect(find.text('68 лет'), findsOneWidget);
      expect(find.text('Врачи для старших'), findsOneWidget);
      expect(find.text('Кардиолог'), findsOneWidget);
      expect(find.text('Анализы Имя Фамилия'), findsOneWidget);
    });
  });

  group('удаление профиля', () {
    final screen = FamilyMemberScreen(
      memberId: 'f1',
      now: DateTime(2026, 8, 6),
    );

    testWidgets('без подтверждения ничего не удаляет', (tester) async {
      final repository = await pumpScreen(tester, screen);

      await tapDelete(tester);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(repository.removed, isEmpty);
    });

    testWidgets('после подтверждения уходит на сервер', (tester) async {
      final repository = await pumpScreen(tester, screen);

      await tapDelete(tester);
      await tester.tap(find.text('Удалить'));
      // Без `pumpAndSettle`: закрывать экран здесь некуда (в приложении он
      // уходит по `pop`), и на месте удалённого остаётся крутиться вечный
      // индикатор загрузки — «настояться» такому экрану не суждено.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.removed, ['f1']);
    });
  });

  testWidgets('неизвестный id показывает индикатор загрузки без падения', (
    tester,
  ) async {
    await pumpScreen(tester, const FamilyMemberScreen(memberId: 'nope'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
