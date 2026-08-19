import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/subscriptions/data/repositories/remote_subscriptions_repository.dart';
import 'package:medix/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:medix/features/subscriptions/domain/entities/payment_method.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/canned_dio.dart';

/// Разбор тарифов и оформление подписки на бэкенде `smart-med`.
///
/// Тела ответов сняты со схем сервера (`PlanOut`, `SubscriptionOut`), а не
/// придуманы: на моках такой разбор не проверяется вовсе — мок и есть уже
/// разобранные данные.
void main() {
  const card = CardDetails(
    number: '4400 4301 1234 5678',
    holder: 'IVAN IVANOV',
    expiry: '0130',
    cvv: '123',
  );

  group('тарифы', () {
    test('цена приходит дробной, а показывается целой', () async {
      final (:dio, adapter: _) = cannedDio({
        '/plans': (
          statusCode: 200,
          body: [
            {
              'id': 'f579ed09-5120-45b3-a0e7-0e11edfde814',
              'code': 'silver',
              'monthly_price': 4990.0,
              'features': {
                'lab_discount_percent': 5,
                'consult_discount_percent': 10,
              },
            },
          ],
        ),
      });

      final plans = await RemoteSubscriptionsRepository(dio).plans();

      expect(plans, hasLength(1));
      expect(plans.single.tier, SubscriptionTier.silver);
      expect(plans.single.pricePerMonth, 4990);
      expect(plans.single.priceLabel, '4990');
    });

    test('снятый с продажи тариф в список не попадает', () async {
      // `PlanCode` на сервере всё ещё знает gold, а продаётся один silver.
      // Если старый стенд отдаст оба, лишняя карточка появиться не должна.
      final (:dio, adapter: _) = cannedDio({
        '/plans': (
          statusCode: 200,
          body: [
            {
              'id': 'p1',
              'code': 'gold',
              'monthly_price': 9999.0,
              'features': null,
            },
            {
              'id': 'p2',
              'code': 'silver',
              'monthly_price': 4990.0,
              'features': null,
            },
          ],
        ),
      });

      final plans = await RemoteSubscriptionsRepository(dio).plans();

      expect(plans.map((plan) => plan.tier), [SubscriptionTier.silver]);
    });
  });

  group('оплата', () {
    test('оформляет подписку выбранного тарифа', () async {
      final (:dio, :adapter) = cannedDio({
        'POST /subscriptions': (
          statusCode: 201,
          body: {
            'subscription': {
              'id': 's1',
              'plan_code': 'silver',
              'status': 'active',
              'period_end': '2026-09-19T10:00:00',
              'cancel_at_period_end': false,
            },
            'payment': {
              'id': 'pay1',
              'kind': 'subscription',
              'amount': 4990.0,
              'target_id': 's1',
              'status': 'paid',
            },
          },
        ),
      });

      final outcome = await RemoteSubscriptionsRepository(
        dio,
      ).pay(card, tier: SubscriptionTier.silver);

      expect(outcome, PaymentOutcome.success);
      // Карта серверу не отправляется: шлюза у него нет, в теле только тариф.
      expect(adapter.requests.single.data, {'plan_code': 'silver'});
    });

    test('отказ сервера — это «оплата не прошла», а не исключение', () async {
      final (:dio, adapter: _) = cannedDio({
        'POST /subscriptions': (
          statusCode: 409,
          body: {'detail': 'подписка уже оформлена'},
        ),
      });

      final outcome = await RemoteSubscriptionsRepository(
        dio,
      ).pay(card, tier: SubscriptionTier.silver);

      expect(outcome, PaymentOutcome.failure);
    });
  });
}
