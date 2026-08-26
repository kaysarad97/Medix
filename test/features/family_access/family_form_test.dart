import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/family_access/presentation/screens/family_list_screen.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_form_screen.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/family_member.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Роутер настоящий, а не `home:`: проверяется возврат по стеку экранов —
  /// список → карточка близкого → форма, — а с одним `home:` стека нет.
  Future<FakeFamilyRepository> pumpForm(
    WidgetTester tester,
    String location,
  ) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    final repository = FakeFamilyRepository();
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: Routes.family,
          builder: (context, state) => const FamilyListScreen(),
        ),
        GoRoute(
          path: Routes.familyMemberNew,
          builder: (context, state) => const FamilyMemberFormScreen(),
        ),
        GoRoute(
          path: Routes.familyMember,
          builder: (context, state) =>
              FamilyMemberScreen(memberId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: Routes.familyMemberEdit,
          builder: (context, state) =>
              FamilyMemberFormScreen(memberId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [familyRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return repository;
  }

  /// Родство больше не набирается руками: поле открывает список.
  Future<void> pickRelation(WidgetTester tester, String label) async {
    await tester.tap(find.text('Родство с Вами'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('добавление', () {
    testWidgets('без даты рождения не сохраняет', (tester) async {
      final repository = await pumpForm(tester, Routes.familyMemberNew);

      await tester.enterText(find.byType(TextField).first, 'Иванов Пётр');
      await pickRelation(tester, 'Ребёнок');
      await tester.tap(find.text('Далее'));
      await tester.pump();

      expect(find.text('Укажите дату рождения'), findsOneWidget);
      expect(repository.added, isEmpty);
    });

    testWidgets('короткое ФИО не уходит на сервер', (tester) async {
      final repository = await pumpForm(tester, Routes.familyMemberNew);

      await tester.enterText(find.byType(TextField).first, 'Пётр');
      await tester.tap(find.text('Далее'));
      await tester.pump();

      expect(find.text('Укажите фамилию и имя'), findsOneWidget);
      expect(find.text('Укажите родство'), findsOneWidget);
      expect(repository.added, isEmpty);
    });
  });

  group('правка', () {
    testWidgets('подставляет данные члена семьи', (tester) async {
      await pumpForm(tester, Routes.familyMemberEditOf('f1'));

      // По содержимому поля, а не по find.text: подпись поля в макете —
      // тоже «Имя Фамилия», и текст нашёлся бы дважды.
      final name = tester.widget<TextField>(find.byType(TextField).first);
      expect(name.controller?.text, 'Имя Фамилия');
      expect(find.text('07/10/2020'), findsOneWidget);
      expect(find.text('Изменить данные'), findsOneWidget);
    });

    testWidgets('родство выбирается из пяти значений сервера', (tester) async {
      final repository = await pumpForm(
        tester,
        Routes.familyMemberEditOf('f1'),
      );

      await pickRelation(tester, 'Родитель');
      await tester.tap(find.text('Далее'));
      await tester.pump();

      expect(repository.updated.single.$2.relation, FamilyRelation.parent);
    });

    testWidgets('сохраняет изменённое ФИО', (tester) async {
      final repository = await pumpForm(
        tester,
        Routes.familyMemberEditOf('f1'),
      );

      await tester.enterText(find.byType(TextField).first, 'Иванов Пётр');
      await tester.tap(find.text('Далее'));
      await tester.pump();

      expect(repository.updated, hasLength(1));
      final (id, draft) = repository.updated.single;
      expect(id, 'f1');
      expect(draft.fullName, 'Иванов Пётр');
      // Родство подставилось из карточки и не потерялось при сохранении.
      expect(draft.relation, FamilyRelation.child);
      expect(draft.birthDate, DateTime(2020, 10, 7));
    });

    testWidgets('удаления в форме больше нет — оно на карточке', (
      tester,
    ) async {
      await pumpForm(tester, Routes.familyMemberEditOf('f1'));

      // Красная надпись под «Далее» была нашей выдумкой, пока у удаления не
      // было макета. Теперь оно кнопкой внизу карточки члена семьи.
      expect(find.text('Удалить профиль'), findsNothing);
    });
  });

  group('возврат', () {
    testWidgets('стрелка закрывает форму добавления', (tester) async {
      await pumpForm(tester, Routes.family);

      await tester.tap(find.text('Добавить профиль'));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyMemberFormScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Без стрелки экран был тупиком: уйти можно было только системным
      // жестом, которого на части устройств нет.
      expect(find.byType(FamilyListScreen), findsOneWidget);
    });

    testWidgets('после удаления возврат ведёт на список, а не в никуда', (
      tester,
    ) async {
      final repository = await pumpForm(tester, Routes.family);

      // Полный путь пользователя: список → карточка близкого → удаление.
      await tester.tap(find.text('Имя Фамилия').first);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Удалить профиль'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Удалить профиль'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(repository.removed, ['f1']);
      // Карточка удалённого закрыта, список на месте — раньше сюда приходили
      // через `go`, и стрелка на списке переставала работать.
      expect(find.byType(FamilyListScreen), findsOneWidget);
      expect(find.byType(FamilyMemberScreen), findsNothing);
    });
  });
}
