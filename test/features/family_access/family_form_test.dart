import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/family_access/presentation/screens/family_list_screen.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_form_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Роутер настоящий, а не `home:`: после удаления форма уходит на список
  /// через `context.go`, и без роутера этот путь было бы не проверить.
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

  group('добавление', () {
    testWidgets('без даты рождения не сохраняет', (tester) async {
      final repository = await pumpForm(tester, Routes.familyMemberNew);

      await tester.enterText(find.byType(TextField).first, 'Иванов Пётр');
      await tester.enterText(find.byType(TextField).last, 'сын');
      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(find.text('Укажите дату рождения'), findsOneWidget);
      expect(repository.added, isEmpty);
    });

    testWidgets('короткое ФИО не уходит на сервер', (tester) async {
      final repository = await pumpForm(tester, Routes.familyMemberNew);

      await tester.enterText(find.byType(TextField).first, 'Пётр');
      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(find.text('Укажите фамилию и имя'), findsOneWidget);
      expect(find.text('Укажите родство'), findsOneWidget);
      expect(repository.added, isEmpty);
    });
  });

  group('правка', () {
    testWidgets('подставляет данные члена семьи', (tester) async {
      await pumpForm(tester, Routes.familyMemberEditOf('f1'));

      expect(find.text('Фамилия Имя'), findsOneWidget);
      expect(find.text('07.10.2020'), findsOneWidget);
      expect(find.text('Изменить данные'), findsOneWidget);
    });

    testWidgets('сохраняет изменённое ФИО', (tester) async {
      final repository = await pumpForm(
        tester,
        Routes.familyMemberEditOf('f1'),
      );

      await tester.enterText(find.byType(TextField).first, 'Иванов Пётр');
      await tester.enterText(find.byType(TextField).last, 'сын');
      await tester.tap(find.text('Сохранить'));
      await tester.pump();

      expect(repository.updated, hasLength(1));
      final (id, draft) = repository.updated.single;
      expect(id, 'f1');
      expect(draft.fullName, 'Иванов Пётр');
      expect(draft.relation, 'сын');
      expect(draft.birthDate, DateTime(2020, 10, 7));
    });

    testWidgets('удаляет только после подтверждения', (tester) async {
      final repository = await pumpForm(
        tester,
        Routes.familyMemberEditOf('f1'),
      );

      await tester.tap(find.text('Удалить из семьи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(repository.removed, isEmpty);

      await tester.tap(find.text('Удалить из семьи'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();

      expect(repository.removed, ['f1']);
      // После удаления возвращаемся на список, а не на карточку удалённого.
      expect(find.byType(FamilyListScreen), findsOneWidget);
    });
  });
}
