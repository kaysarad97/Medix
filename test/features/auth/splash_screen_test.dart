import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/auth/presentation/providers/session_providers.dart';
import 'package:medix/features/auth/presentation/screens/splash_screen.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Маленький роутер вместо боевого: тут проверяется только развилка
  /// заставки, а тянуть в тест все два десятка экранов незачем.
  GoRouter buildRouter() => GoRouter(
    initialLocation: Routes.splash,
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const Text('ЛОГИН')),
      GoRoute(path: Routes.home, builder: (_, _) => const Text('ГЛАВНАЯ')),
    ],
  );

  Future<void> pumpSplash(WidgetTester tester, {required bool hasSession}) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasStoredSessionProvider.overrideWith((ref) async => hasSession),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: buildRouter(),
        ),
      ),
    );
  }

  testWidgets('без сохранённой сессии ведёт на логин', (tester) async {
    await pumpSplash(tester, hasSession: false);

    // Пока держится минимальная выдержка, заставка ещё на экране.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ЛОГИН'), findsNothing);

    await tester.pump(SplashScreen.minimumVisible);
    await tester.pumpAndSettle();

    expect(find.text('ЛОГИН'), findsOneWidget);
  });

  testWidgets('с сохранённой сессией ведёт на главную', (tester) async {
    await pumpSplash(tester, hasSession: true);

    await tester.pump(SplashScreen.minimumVisible);
    await tester.pumpAndSettle();

    expect(find.text('ГЛАВНАЯ'), findsOneWidget);
    expect(find.text('ЛОГИН'), findsNothing);
  });

  testWidgets('логотип не мигает одним кадром', (tester) async {
    await pumpSplash(tester, hasSession: true);

    // Проверка хранилища занимает миллисекунды; без выдержки заставка
    // исчезла бы почти сразу и выглядела бы сбоем отрисовки.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(SplashScreen.minimumVisible);
    await tester.pumpAndSettle();
  });
}
