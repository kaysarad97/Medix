import '../../../../core/widgets/icon_chip.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/subscription_plan.dart';

/// Чем кончилась попытка оплаты. Экран результата один на оба исхода —
/// см. `design/Оплата прошла.png` и `design/Оплата НЕ прошла.png`.
enum PaymentOutcome { success, failure }

abstract interface class SubscriptionsRepository {
  Future<List<PlanFeature>> features();

  Future<List<SubscriptionPlan>> plans();

  /// Отправляет карту в платёжный шлюз. Данные держателя карты нигде не
  /// сохраняются — см. пояснение в [CardDetails].
  Future<PaymentOutcome> pay(CardDetails card);
}

/// Заглушка на время разработки бэкенда. Данные — с макета
/// `design/Подписка.png`.
class MockSubscriptionsRepository implements SubscriptionsRepository {
  const MockSubscriptionsRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<List<PlanFeature>> features() async {
    await Future<void>.delayed(_latency);
    return mockFeatures;
  }

  @override
  Future<List<SubscriptionPlan>> plans() async {
    await Future<void>.delayed(_latency);
    return mockPlans;
  }

  @override
  Future<PaymentOutcome> pay(CardDetails card) async {
    await Future<void>.delayed(_latency);
    // Сценарий заглушки, как у логина: карта, начинающаяся на 0000, всегда
    // отбивается — иначе экран «Оплата НЕ прошла» не проверить.
    final digits = card.number.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0000')
        ? PaymentOutcome.failure
        : PaymentOutcome.success;
  }

  static const List<PlanFeature> mockFeatures = [
    PlanFeature(
      title: 'Скидки на анализы',
      subtitle: 'в партнерских лабораториях',
      icon: MedixIcon.planDiscount,
      values: {
        SubscriptionTier.free: null,
        SubscriptionTier.silver: '5-7%',
        SubscriptionTier.gold: '10-15%',
      },
    ),
    PlanFeature(
      title: 'Скидка на консультации',
      subtitle: 'у проверенных врачей',
      icon: MedixIcon.planPrice,
      values: {
        SubscriptionTier.free: null,
        SubscriptionTier.silver: '10%',
        SubscriptionTier.gold: 'Пакет\nуслуг',
      },
    ),
    PlanFeature(
      title: 'Очередь к врачу',
      subtitle: 'время ожидания приема',
      icon: MedixIcon.planQueue,
      values: {
        SubscriptionTier.free: 'Общая',
        SubscriptionTier.silver: 'Общая',
        SubscriptionTier.gold: 'Приоритет',
      },
    ),
    PlanFeature(
      title: 'Аналитика здоровья',
      subtitle: 'история заболевания',
      icon: MedixIcon.planAnalytics,
      values: {
        SubscriptionTier.free: null,
        SubscriptionTier.silver: 'Графики\n(история)',
        SubscriptionTier.gold: 'ИИ-бот,\nграфики',
      },
    ),
    PlanFeature(
      title: 'Семейный доступ',
      subtitle: 'мед-карты для',
      icon: MedixIcon.planFamily,
      values: {
        SubscriptionTier.free: null,
        SubscriptionTier.silver: null,
        SubscriptionTier.gold: 'До 3-5\nпрофилей',
      },
    ),
  ];

  /// В макете продаются только два тарифа: Gold слева, Silver справа.
  /// Basic — это отсутствие подписки, его карточки нет.
  static const List<SubscriptionPlan> mockPlans = [
    SubscriptionPlan(tier: SubscriptionTier.gold, pricePerMonth: 9999),
    SubscriptionPlan(tier: SubscriptionTier.silver, pricePerMonth: 5999),
  ];
}
