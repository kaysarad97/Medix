import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/medix_wait_view.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:medix/features/subscriptions/domain/entities/payment_method.dart';
import 'package:medix/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:medix/features/subscriptions/presentation/screens/card_form_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/payment_method_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/payment_result_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/subscription_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_subscriptions_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionsRepositoryProvider.overrideWithValue(
            const FakeSubscriptionsRepository(),
          ),
        ],
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
  }

  testWidgets('подписка рисует таблицу и цены', (tester) async {
    await pump(tester, const SubscriptionScreen());

    expect(find.text('Оформите подписку'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Silver'), findsNWidgets(2)); // колонка и карточка
    expect(find.text('Скидки на анализы'), findsOneWidget);
    expect(find.text('9999'), findsOneWidget);
    expect(find.text('5999'), findsOneWidget);
    expect(find.text('или продолжить без подписки'), findsOneWidget);
  });

  testWidgets('выбор способа оплаты рисует все методы', (tester) async {
    await pump(tester, const PaymentMethodScreen());

    expect(find.text('Оплата через Kaspi.kz'), findsOneWidget);
    expect(find.text('Оплата через Halyk Bank'), findsOneWidget);
    expect(find.text('Оплата через Apple Pay'), findsOneWidget);
    expect(find.text('Оплата через другие банки'), findsOneWidget);
    expect(find.text('Сохраненные карты'), findsOneWidget);
  });

  group('форма карты', () {
    testWidgets('кнопка неактивна, пока поля не заполнены', (tester) async {
      await pump(tester, const CardFormScreen());

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('кнопка включается после заполнения всех полей', (
      tester,
    ) async {
      await pump(tester, const CardFormScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '4400430112345678');
      await tester.enterText(fields.at(1), 'IMYA FAMILIYA');
      await tester.enterText(fields.at(2), '0130');
      await tester.enterText(fields.at(3), '123');
      await tester.pump();

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('пока идёт проверка, показывается экран ожидания', (
      tester,
    ) async {
      await pump(tester, const CardFormScreen(animatedWait: false));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '4400430112345678');
      await tester.enterText(fields.at(1), 'IMYA FAMILIYA');
      await tester.enterText(fields.at(2), '0130');
      await tester.enterText(fields.at(3), '123');
      await tester.pump();

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(find.byType(MedixWaitView), findsOneWidget);
      expect(find.text('подождите...'), findsOneWidget);
      expect(find.text('проверяем данные карты...'), findsOneWidget);

      // Досиживаем выдержку, иначе тест уйдёт с висящим таймером. Сначала
      // даём разрешиться самой оплате — таймер выдержки создаётся только
      // после неё, и прокручивать часы раньше бесполезно.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    });

    testWidgets('номер карты принимает только цифры и не длиннее 16', (
      tester,
    ) async {
      await pump(tester, const CardFormScreen());

      await tester.enterText(
        find.byType(TextField).at(0),
        'abc12345678901234567',
      );
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField).at(0));
      expect(field.controller!.text, '1234567890123456');
    });
  });

  group('итог оплаты', () {
    testWidgets('успех', (tester) async {
      await pump(
        tester,
        const PaymentResultScreen(outcome: PaymentOutcome.success),
      );

      expect(find.text('Карта успешно сохранена!'), findsOneWidget);
      expect(find.text('На главную страницу'), findsOneWidget);
    });

    testWidgets('отказ', (tester) async {
      await pump(
        tester,
        const PaymentResultScreen(outcome: PaymentOutcome.failure),
      );

      expect(find.text('Неверные данные карты'), findsOneWidget);
      expect(find.text('Попробовать еще раз'), findsOneWidget);
    });
  });

  group('данные карты', () {
    test('видны только последние четыре цифры', () {
      const card = CardDetails(
        number: '4400 4301 1234 5678',
        holder: 'IMYA FAMILIYA',
        expiry: '0130',
        cvv: '123',
      );
      expect(card.lastFour, '5678');
      expect(card.isComplete, isTrue);
    });

    test('неполная карта не уходит в шлюз', () {
      const card = CardDetails(number: '4400', holder: '', expiry: '', cvv: '');
      expect(card.isComplete, isFalse);
    });

    test('номер разбивается по четыре', () {
      expect(
        CardDetails.formatNumber('4400430112345678'),
        '4400 4301 1234 5678',
      );
    });

    test('заглушка отбивает карты, начинающиеся на 0000', () async {
      const repo = MockSubscriptionsRepository();
      const bad = CardDetails(
        number: '0000430112345678',
        holder: 'A',
        expiry: '0130',
        cvv: '123',
      );
      expect(await repo.pay(bad), PaymentOutcome.failure);
    });
  });
}
