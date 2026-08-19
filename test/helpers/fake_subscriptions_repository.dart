import 'package:medix/features/subscriptions/data/plan_features.dart';
import 'package:medix/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:medix/features/subscriptions/domain/entities/payment_method.dart';
import 'package:medix/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:medix/shared/models/subscription_tier.dart';

/// Те же данные, что у [MockSubscriptionsRepository], но без задержки:
/// таймер вне `runAsync` роняет виджет-тест на «timersPending».
class FakeSubscriptionsRepository implements SubscriptionsRepository {
  const FakeSubscriptionsRepository();

  @override
  Future<List<PlanFeature>> features() async => designPlanFeatures;

  @override
  Future<List<SubscriptionPlan>> plans() async =>
      MockSubscriptionsRepository.mockPlans;

  @override
  Future<PaymentOutcome> pay(
    CardDetails card, {
    required SubscriptionTier tier,
  }) async {
    // Правило то же, что в заглушке, но без её задержки: делегировать нельзя,
    // иначе в тест приезжает лишний таймер.
    final digits = card.number.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0000')
        ? PaymentOutcome.failure
        : PaymentOutcome.success;
  }
}
