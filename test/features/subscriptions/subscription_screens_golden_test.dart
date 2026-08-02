@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:medix/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:medix/features/subscriptions/presentation/screens/card_form_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/payment_method_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/payment_result_screen.dart';
import 'package:medix/features/subscriptions/presentation/screens/subscription_screen.dart';

import '../../helpers/fake_subscriptions_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны экранов подписки и оплаты для сверки с `design/Подписка.png`,
/// `design/Оплата.png`, `design/Ввод данных карты.png` и двумя итогами.
///
/// РАСХОЖДЕНИЕ: иконки строк таблицы сравнения (процент, доллар, планшет,
/// график, группа людей) дизайнер не отдавал — на их месте пустота.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
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
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );

    await tester.runAsync(() async {
      for (final asset in ['app_bg.png', 'auth_bg.png']) {
        await precacheImage(
          AssetImage('assets/images/$asset'),
          tester.element(find.byType(MaterialApp)),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('subscription соответствует эталону', (tester) async {
    await pumpScreen(tester, const SubscriptionScreen(), const Size(440, 956));
    await expectLater(
      find.byType(SubscriptionScreen),
      matchesGoldenFile('goldens/subscription.png'),
    );
  });

  testWidgets('payment_method соответствует эталону', (tester) async {
    await pumpScreen(tester, const PaymentMethodScreen(), const Size(440, 956));
    await expectLater(
      find.byType(PaymentMethodScreen),
      matchesGoldenFile('goldens/payment_method.png'),
    );
  });

  testWidgets('card_form соответствует эталону', (tester) async {
    await pumpScreen(tester, const CardFormScreen(), const Size(440, 956));
    await expectLater(
      find.byType(CardFormScreen),
      matchesGoldenFile('goldens/card_form.png'),
    );
  });

  testWidgets('payment_success соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      // С обработчиком: без него кнопка рисуется приглушённой, а в макете
      // она активна.
      PaymentResultScreen(outcome: PaymentOutcome.success, onContinue: () {}),
      const Size(440, 956),
    );
    await expectLater(
      find.byType(PaymentResultScreen),
      matchesGoldenFile('goldens/payment_success.png'),
    );
  });

  testWidgets('payment_failure соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      PaymentResultScreen(outcome: PaymentOutcome.failure, onContinue: () {}),
      const Size(440, 956),
    );
    await expectLater(
      find.byType(PaymentResultScreen),
      matchesGoldenFile('goldens/payment_failure.png'),
    );
  });
}
