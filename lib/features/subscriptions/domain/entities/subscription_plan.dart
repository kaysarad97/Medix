import '../../../../core/widgets/icon_chip.dart';
import '../../../../shared/models/subscription_tier.dart';

/// Строка таблицы сравнения тарифов на `design/Подписка.png`.
///
/// В каждой ячейке либо текст («5-7%», «Приоритет»), либо перечёркнутый
/// кружок — значит, на этом тарифе возможности нет.
class PlanFeature {
  const PlanFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.values,
  });

  /// «Скидки на анализы».
  final String title;

  /// Синяя приписка под ним: «в партнерских лабораториях».
  final String subtitle;

  /// Глиф слева от подписи.
  final MedixIcon icon;

  /// Что стоит в колонке тарифа. `null` — возможности нет.
  final Map<SubscriptionTier, String?> values;

  String? valueFor(SubscriptionTier tier) => values[tier];
}

/// Тариф с ценой — карточка под таблицей.
class SubscriptionPlan {
  const SubscriptionPlan({required this.tier, required this.pricePerMonth});

  final SubscriptionTier tier;

  /// Цена в тенге за месяц.
  final int pricePerMonth;

  /// «9999» — разряды не разделяем, так в макете.
  String get priceLabel => pricePerMonth.toString();
}

class SubscriptionCancellation {
  const SubscriptionCancellation({
    required this.periodEnd,
    required this.cancelAtPeriodEnd,
  });

  final DateTime periodEnd;
  final bool cancelAtPeriodEnd;
}
