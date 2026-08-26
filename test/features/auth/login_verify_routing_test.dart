import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/auth/data/repositories/auth_repository.dart';
import 'package:medix/features/auth/presentation/providers/auth_providers.dart';
import 'package:medix/features/auth/presentation/providers/login_controller.dart';
import 'package:medix/features/auth/presentation/screens/login_verify_screen.dart';
import 'package:medix/features/auth/presentation/widgets/otp_code_input.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

/// Тот же путь, что и `LoginVerifyScreen.ref.listen`, но с реальной
/// навигацией через `GoRouter` — `login_controller_test.dart` проверяет
/// только состояние контроллера, сам экран его никогда не слушал в тестах.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpAndSubmit(
    WidgetTester tester, {
    required String email,
  }) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(const MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    // Экран показывает только `state.email`, поле для ввода — на шаге
    // «Логин». Здесь оно предзаполнено так, будто шаг 1 уже пройден.
    container.read(loginControllerProvider.notifier).emailChanged(email);

    final router = GoRouter(
      initialLocation: Routes.loginVerify,
      routes: [
        GoRoute(
          path: Routes.loginVerify,
          builder: (_, _) => const LoginVerifyScreen(),
        ),
        GoRoute(path: Routes.home, builder: (_, _) => const Text('ГЛАВНАЯ')),
        GoRoute(
          path: Routes.doctorHome,
          builder: (_, _) => const Text('КАБИНЕТ ВРАЧА'),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byType(TextField).first,
      MockAuthRepository.validCode,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
  }

  testWidgets('пациент после кода попадает на главную', (tester) async {
    await pumpAndSubmit(tester, email: 'patient@medix.kz');

    expect(find.text('ГЛАВНАЯ'), findsOneWidget);
    expect(find.text('КАБИНЕТ ВРАЧА'), findsNothing);
    expect(find.byType(OtpCodeInput), findsNothing);
  });

  testWidgets('врач после кода попадает в кабинет', (tester) async {
    await pumpAndSubmit(tester, email: MockAuthRepository.doctorEmail);

    expect(find.text('КАБИНЕТ ВРАЧА'), findsOneWidget);
    expect(find.text('ГЛАВНАЯ'), findsNothing);
    expect(find.byType(OtpCodeInput), findsNothing);
  });
}
