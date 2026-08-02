import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/subscriptions_repository.dart';
import '../../domain/entities/subscription_plan.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockSubscriptionsRepository(),
);

final planFeaturesProvider = FutureProvider<List<PlanFeature>>(
  (ref) => ref.watch(subscriptionsRepositoryProvider).features(),
);

final plansProvider = FutureProvider<List<SubscriptionPlan>>(
  (ref) => ref.watch(subscriptionsRepositoryProvider).plans(),
);
