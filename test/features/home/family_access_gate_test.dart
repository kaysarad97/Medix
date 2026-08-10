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
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Семейный доступ входит в Gold: без подписки «Моя Семья» на главной ведёт
/// на экран тарифов, а не в профиль близкого.
///
/// Роутер здесь свой, из трёх маршрутов: настоящий тянет за собой
/// репозитории всех экранов сразу, а проверить надо ровно одну развилку.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpHome(WidgetTester tester, SubscriptionTier tier) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
        GoRoute(
          path: Routes.subscription,
          builder: (_, _) => const Text('экран тарифов'),
        ),
        GoRoute(
          path: Routes.familyMember,
          builder: (_, _) => const Text('профиль близкого'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          specialtiesProvider.overrideWith((ref) => const []),
          upcomingAppointmentsProvider.overrideWith((ref) => const []),
          familyRepositoryProvider.overrideWithValue(
            const FakeFamilyRepository(),
          ),
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

  Future<void> tapFamilyRow(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Профиль для ребенка'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Профиль для ребенка'));
    await tester.pumpAndSettle();
  }

  testWidgets('без подписки открывается экран тарифов', (tester) async {
    await pumpHome(tester, SubscriptionTier.free);
    await tapFamilyRow(tester);

    expect(find.text('экран тарифов'), findsOneWidget);
    expect(find.text('профиль близкого'), findsNothing);
  });

  testWidgets('с Gold открывается профиль близкого', (tester) async {
    await pumpHome(tester, SubscriptionTier.gold);
    await tapFamilyRow(tester);

    expect(find.text('профиль близкого'), findsOneWidget);
    expect(find.text('экран тарифов'), findsNothing);
  });
}
