import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/app_checkbox.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/shared/models/app_language.dart';
import 'package:medix/features/auth/presentation/providers/registration_controller.dart';
import 'package:medix/features/auth/presentation/screens/app_settings_screen.dart';
import 'package:medix/features/auth/presentation/screens/policy_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/auth_overrides.dart';
import '../../helpers/test_fonts.dart';

/// Экраны сами больше не читают `registrationControllerProvider` — тем же
/// приёмом их подключает `app_router.dart`, здесь он повторён без роутера.
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
    await tester.pump();
  }

  PrimaryButton button(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton));

  group('Настройки приложения', () {
    testWidgets('показывает три языка, казахский подписан на казахском', (
      tester,
    ) async {
      await pumpScreen(tester, const _AppSettingsHost());

      expect(find.text('Настройки приложения'), findsOneWidget);
      // Голая проверка наличия строки заодно ловит подмену шрифта на такой,
      // где нет казахских букв: текст остаётся, но рисуется квадратами —
      // это отлавливает golden. Здесь фиксируем сам состав списка.
      expect(find.text('Қазақша'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('кнопка заблокирована, пока язык не выбран', (tester) async {
      await pumpScreen(tester, const _AppSettingsHost());
      expect(button(tester).onPressed, isNull);

      await tester.tap(find.text('Русский'));
      await tester.pump();

      expect(button(tester).onPressed, isNotNull);
    });

    testWidgets('согласие на рассылки не обязательно для перехода', (
      tester,
    ) async {
      await pumpScreen(tester, const _AppSettingsHost());

      await tester.tap(find.text('Қазақша'));
      await tester.pump();

      // Кружок не тронут, а кнопка активна: согласие на рекламные рассылки
      // нельзя делать условием регистрации.
      expect(button(tester).onPressed, isNotNull);
    });
  });

  group('Политика', () {
    testWidgets('кнопка заблокирована, пока согласие не отмечено', (
      tester,
    ) async {
      await pumpScreen(tester, const _PolicyHost());
      expect(button(tester).onPressed, isNull);

      await tester.tap(find.byType(AppCheckbox));
      await tester.pump();

      expect(button(tester).onPressed, isNotNull);
    });

    testWidgets('видна пометка о несогласованном тексте', (tester) async {
      await pumpScreen(tester, const _PolicyHost());

      expect(find.textContaining('не согласован с юристом'), findsOneWidget);
    });
  });

  group('контроллер: шаги 4 и 5', () {
    late ProviderContainer container;
    setUp(() => container = ProviderContainer(overrides: authOverrides));
    tearDown(() => container.dispose());

    test('шаг 4 не проходит без выбора языка', () {
      final c = container.read(registrationControllerProvider.notifier);
      expect(c.submitAppSettings(), isFalse);

      c.setLanguage(AppLanguage.kk);
      expect(c.submitAppSettings(), isTrue);
    });

    test('шаг 5 не проходит без принятия политики', () {
      final c = container.read(registrationControllerProvider.notifier);
      expect(c.submitPolicy(), isFalse);

      c.setPolicyAccepted(true);
      expect(c.submitPolicy(), isTrue);
    });

    test('язык и согласия переживают правку текстовых полей', () {
      final c = container.read(registrationControllerProvider.notifier);
      c
        ..setLanguage(AppLanguage.en)
        ..setPushConsent(true)
        ..setPolicyAccepted(true)
        ..setField(RegField.email, 'user@medix.kz');

      final state = container.read(registrationControllerProvider);
      expect(state.language, AppLanguage.en);
      expect(state.pushConsent, isTrue);
      expect(state.policyAccepted, isTrue);
    });
  });
}
