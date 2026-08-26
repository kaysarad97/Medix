@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/auth/presentation/providers/registration_controller.dart';
import 'package:medix/features/auth/presentation/screens/app_settings_screen.dart';
import 'package:medix/features/auth/presentation/screens/personal_data_screen.dart';
import 'package:medix/features/auth/presentation/screens/policy_screen.dart';
import 'package:medix/features/auth/presentation/screens/register_role_screen.dart';
import 'package:medix/features/auth/presentation/screens/register_screen.dart';
import 'package:medix/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/auth_overrides.dart';
import '../../helpers/test_fonts.dart';

class _AppSettingsHost extends ConsumerWidget {
  const _AppSettingsHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);
    return AppSettingsScreen(
      language: state.language,
      pushConsent: state.pushConsent,
      onLanguageSelected: controller.setLanguage,
      onPushConsentChanged: controller.setPushConsent,
      onNext: state.language == null
          ? null
          : () => controller.submitAppSettings(),
    );
  }
}

class _PolicyHost extends ConsumerWidget {
  const _PolicyHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);
    return PolicyScreen(
      policyAccepted: state.policyAccepted,
      onPolicyAcceptedChanged: controller.setPolicyAccepted,
      onNext: state.policyAccepted ? () => controller.submitPolicy() : null,
    );
  }
}

/// Эталонные рендеры шагов регистрации для сверки с макетами в `design/`.
///
/// Обновление: `flutter test --update-goldens`.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: authOverrides,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/auth_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    // Именно pump, а не pumpAndSettle: на экране кода тикает Timer.periodic,
    // и settle крутился бы до таймаута.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Логин Выбор соответствует эталону', (tester) async {
    await pumpScreen(tester, const RegisterRoleScreen());

    await expectLater(
      find.byType(RegisterRoleScreen),
      matchesGoldenFile('goldens/register_role.png'),
    );
  });

  testWidgets('Создайте профиль соответствует эталону', (tester) async {
    await pumpScreen(tester, const RegisterScreen());

    await expectLater(
      find.byType(RegisterScreen),
      matchesGoldenFile('goldens/register_credentials.png'),
    );
  });

  testWidgets('Ваши данные соответствует эталону', (tester) async {
    await pumpScreen(tester, const PersonalDataScreen());

    await expectLater(
      find.byType(PersonalDataScreen),
      matchesGoldenFile('goldens/register_personal_data.png'),
    );
  });

  testWidgets('Введите код соответствует эталону', (tester) async {
    await pumpScreen(tester, const VerifyCodeScreen());

    await expectLater(
      find.byType(VerifyCodeScreen),
      matchesGoldenFile('goldens/register_verify_code.png'),
    );

    // Гасим обратный отсчёт, иначе тест падает на «pending timer».
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Настройки приложения соответствует эталону', (tester) async {
    await pumpScreen(tester, const _AppSettingsHost());

    await expectLater(
      find.byType(AppSettingsScreen),
      matchesGoldenFile('goldens/register_app_settings.png'),
    );
  });

  testWidgets('Политика соответствует эталону', (tester) async {
    await pumpScreen(tester, const _PolicyHost());

    await expectLater(
      find.byType(PolicyScreen),
      matchesGoldenFile('goldens/register_policy.png'),
    );
  });
}
