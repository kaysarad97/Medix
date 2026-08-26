import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../data/repositories/remote_subscriptions_repository.dart';
import '../../data/repositories/subscriptions_repository.dart';
import '../../domain/entities/subscription_plan.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((
  ref,
) {
  if (useMocks) return const MockSubscriptionsRepository();

  return RemoteSubscriptionsRepository(ref.watch(dioClientProvider));
});

final planFeaturesProvider = FutureProvider<List<PlanFeature>>(
  (ref) => ref.watch(subscriptionsRepositoryProvider).features(),
);

/// Тарифы с ценами.
///
/// `autoDispose` — цена приходит с сервера, и без сброса кэша экран показывал
/// бы ту, что прочиталась при первом открытии за запуск. На живом API так уже
/// ловили расписание врача и уведомления.
final plansProvider = FutureProvider.autoDispose<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionsRepositoryProvider).plans(),
);

/// Тариф, выбранный на экране «Варианты подписки».
///
/// Живёт между тремя экранами: карточку нажимают на первом, а подписка
/// оформляется на последнем, при оплате. В оплату можно войти и мимо выбора
/// — из настроек профиля, — поэтому значение по умолчанию не пустое:
/// платный тариф остался один.
class SelectedPlan extends Notifier<SubscriptionTier> {
  @override
  SubscriptionTier build() => SubscriptionTier.silver;

  void select(SubscriptionTier tier) => state = tier;
}

final selectedPlanProvider = NotifierProvider<SelectedPlan, SubscriptionTier>(
  SelectedPlan.new,
);
