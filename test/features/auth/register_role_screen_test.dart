import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/auth/presentation/screens/register_role_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

/// Свёрстан по `design/врач фрилансер/Логин Выбор.png` — выбор роли перед
/// шагом почты. Навигация проверяется через реальный `GoRouter`, как в
/// `login_verify_routing_test.dart`.
void main() {
  setUpAll(loadAppFonts);

  Future<GoRouter> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: Routes.registerRoleChoice,
      routes: [
        GoRoute(
          path: Routes.registerRoleChoice,
          builder: (_, _) => const RegisterRoleScreen(),
        ),
        GoRoute(
          path: Routes.register,
          builder: (_, _) => const Text('ШАГ ПОЧТЫ'),
        ),
        GoRoute(
          path: Routes.doctorRegister,
          builder: (_, _) => const Text('ДАННЫЕ ВРАЧА'),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pump();
    return router;
  }

  testWidgets('рисует заголовок и обе роли', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Создайте профиль'), findsOneWidget);
    expect(find.text('Я — клиент'), findsOneWidget);
    expect(find.text('Я — врач'), findsOneWidget);
  });

  testWidgets('«Я — клиент» ведёт на шаг почты', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Я — клиент'));
    await tester.pumpAndSettle();

    expect(find.text('ШАГ ПОЧТЫ'), findsOneWidget);
  });

  testWidgets('«Я — врач» ведёт в данные врача', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Я — врач'));
    await tester.pumpAndSettle();

    expect(find.text('ДАННЫЕ ВРАЧА'), findsOneWidget);
  });
}
