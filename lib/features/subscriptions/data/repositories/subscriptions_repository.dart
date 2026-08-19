import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/subscription_plan.dart';
import '../plan_features.dart';

/// Чем кончилась попытка оплаты. Экран результата один на оба исхода —
/// см. `design/Оплата прошла.png` и `design/Оплата НЕ прошла.png`.
enum PaymentOutcome { success, failure }

abstract interface class SubscriptionsRepository {
  Future<List<PlanFeature>> features();

  Future<List<SubscriptionPlan>> plans();

  /// Оплачивает подписку выбранного тарифа. Данные держателя карты нигде не
  /// сохраняются — см. пояснение в [CardDetails].
  ///
  /// Тариф нужен здесь, а не на экране выбора: подписка оформляется в конце
  /// оплаты, и до неё сервер о выборе не знает.
  Future<PaymentOutcome> pay(
    CardDetails card, {
    required SubscriptionTier tier,
  });
}

/// Заглушка на время разработки бэкенда. Данные — с макета
/// `design/Подписка.png`.
class MockSubscriptionsRepository implements SubscriptionsRepository {
  const MockSubscriptionsRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<List<PlanFeature>> features() async {
    await Future<void>.delayed(_latency);
    return designPlanFeatures;
  }

  @override
  Future<List<SubscriptionPlan>> plans() async {
    await Future<void>.delayed(_latency);
    return mockPlans;
  }

  @override
  Future<PaymentOutcome> pay(
    CardDetails card, {
    required SubscriptionTier tier,
  }) async {
    await Future<void>.delayed(_latency);
    // Сценарий заглушки, как у логина: карта, начинающаяся на 0000, всегда
    // отбивается — иначе экран «Оплата НЕ прошла» не проверить.
    final digits = card.number.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0000')
        ? PaymentOutcome.failure
        : PaymentOutcome.success;
  }

  /// Продаётся один тариф: Gold снят, Basic — это отсутствие подписки, и
  /// карточки с ценой у него нет.
  static const List<SubscriptionPlan> mockPlans = [
    SubscriptionPlan(tier: SubscriptionTier.silver, pricePerMonth: 5999),
  ];
}
