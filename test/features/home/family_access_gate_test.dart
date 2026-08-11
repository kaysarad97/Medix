import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/home/presentation/providers/home_providers.dart';
import 'package:medix/features/home/presentation/screens/home_screen.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/medical_card_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Семейный доступ входит в Gold: без подписки «Моя Семья» ведёт на экран
/// тарифов, а не в профиль близкого и не в список семьи. Проверяются оба
/// входа — с главной и с «Ваша Мед-Карта».
///
/// Роутер здесь свой, из четырёх маршрутов: настоящий тянет за собой
/// репозитории всех экранов сразу, а проверить надо ровно одну развилку.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester,
    SubscriptionTier tier, {
    required Widget screen,
  }) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(
          path: Routes.subscription,
          builder: (_, _) => const Text('экран тарифов'),
        ),
        GoRoute(
          path: Routes.familyMember,
          builder: (_, _) => const Text('профиль близкого'),
        ),
        GoRoute(
          path: Routes.family,
          builder: (_, _) => const Text('список семьи'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          specialtiesProvider.overrideWith((ref) => const []),
          upcomingAppointmentsProvider.overrideWith((ref) => const []),
          familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
          profileRepositoryProvider.overrideWithValue(
            FakeProfileRepository(subscription: tier),
          ),
        ],
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
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('главная', () {
    testWidgets('без подписки открывается экран тарифов', (tester) async {
      await pumpScreen(
        tester,
        SubscriptionTier.free,
        screen: const HomeScreen(),
      );
      await tapText(tester, 'Профиль для ребенка');

      expect(find.text('экран тарифов'), findsOneWidget);
      expect(find.text('профиль близкого'), findsNothing);
    });

    testWidgets('с Gold открывается профиль близкого', (tester) async {
      await pumpScreen(
        tester,
        SubscriptionTier.gold,
        screen: const HomeScreen(),
      );
      await tapText(tester, 'Профиль для ребенка');

      expect(find.text('профиль близкого'), findsOneWidget);
      expect(find.text('экран тарифов'), findsNothing);
    });
  });

  group('«Ваша Мед-Карта»', () {
    // Дата фиксированная: в шапке считается возраст.
    final screen = MedicalCardScreen(now: DateTime(2026, 8, 2));

    testWidgets('без подписки заголовок ведёт на тарифы', (tester) async {
      await pumpScreen(tester, SubscriptionTier.free, screen: screen);
      await tapText(tester, 'Моя Семья');

      expect(find.text('экран тарифов'), findsOneWidget);
      expect(find.text('список семьи'), findsNothing);
    });

    testWidgets('с Gold заголовок ведёт на список семьи', (tester) async {
      await pumpScreen(tester, SubscriptionTier.gold, screen: screen);
      await tapText(tester, 'Моя Семья');

      expect(find.text('список семьи'), findsOneWidget);
      expect(find.text('экран тарифов'), findsNothing);
    });

    testWidgets('без подписки строка участника тоже под замком', (
      tester,
    ) async {
      await pumpScreen(tester, SubscriptionTier.free, screen: screen);
      // Обоих мок-членов семьи зовут одинаково — берём первую строку.
      final row = find.text('Имя Фамилия').first;
      await tester.scrollUntilVisible(
        row,
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text('экран тарифов'), findsOneWidget);
      expect(find.text('профиль близкого'), findsNothing);
    });
  });
}
