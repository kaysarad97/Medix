import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/repositories/lab_api_repository.dart';
import '../../data/repositories/lab_services_repository.dart';
import '../../domain/entities/lab_offer.dart';
import '../../domain/entities/lab_service.dart';
import '../../domain/entities/lab_workflow.dart';

final labApiRepositoryProvider = Provider<LabApiRepository>(
  (ref) => LabApiRepository(ref.watch(dioClientProvider)),
);

final labReferralProvider = FutureProvider.autoDispose
    .family<LabReferral, String>(
      (ref, id) => ref.watch(labApiRepositoryProvider).referral(id),
    );

final referralLabOffersProvider = FutureProvider.autoDispose
    .family<List<LabPriceOffer>, String>(
      (ref, id) => ref.watch(labApiRepositoryProvider).offers(id),
    );

final labOrdersProvider = FutureProvider.autoDispose<List<LabOrder>>(
  (ref) => ref.watch(labApiRepositoryProvider).orders(),
);

final labResultsProvider = FutureProvider.autoDispose<List<LabResultFile>>(
  (ref) => ref.watch(labApiRepositoryProvider).results(),
);

final labResultDownloadProvider = FutureProvider.autoDispose
    .family<LabResultDownload, String>(
      (ref, resultId) =>
          ref.watch(labApiRepositoryProvider).resultDownload(resultId),
    );

final labServicesRepositoryProvider = Provider<LabServicesRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockLabServicesRepository(),
);

final labServicesProvider = FutureProvider<List<LabService>>(
  (ref) => ref.watch(labServicesRepositoryProvider).services(),
);

/// Строка поиска в «Какой анализ Вам нужен?».
class LabServiceSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final labServiceSearchQueryProvider =
    NotifierProvider<LabServiceSearchQuery, String>(LabServiceSearchQuery.new);

/// Вкладка «отдельные анализы» / «комплексы анализов».
class LabServiceKindFilter extends Notifier<LabServiceKind> {
  @override
  LabServiceKind build() => LabServiceKind.individual;

  void select(LabServiceKind kind) => state = kind;
}

final labServiceKindFilterProvider =
    NotifierProvider<LabServiceKindFilter, LabServiceKind>(
      LabServiceKindFilter.new,
    );

/// Услуги с учётом вкладки и поиска, сгруппированные по первой букве
/// названия — так, как строится список на экране.
final visibleLabServicesProvider = Provider<Map<String, List<LabService>>>((
  ref,
) {
  final all = ref.watch(labServicesProvider).value ?? const [];
  final kind = ref.watch(labServiceKindFilterProvider);
  final query = ref.watch(labServiceSearchQueryProvider).trim().toLowerCase();

  final filtered = all.where((s) {
    if (s.kind != kind) return false;
    if (query.isEmpty) return true;
    return s.name.toLowerCase().contains(query);
  }).toList();

  final grouped = <String, List<LabService>>{};
  for (final service in filtered) {
    grouped.putIfAbsent(service.letter, () => []).add(service);
  }
  return grouped;
});

/// Корзина: id выбранных услуг. Живёт на экране — до бэкенда с заказами
/// сохранять её негде.
class LabServicesCart extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) {
    final next = {...state};
    if (!next.remove(id)) next.add(id);
    state = next;
  }
}

final labServicesCartProvider = NotifierProvider<LabServicesCart, Set<String>>(
  LabServicesCart.new,
);

/// Услуги, лежащие в корзине, в порядке каталога — так их нумерует макет.
final cartServicesProvider = Provider<List<LabService>>((ref) {
  final ids = ref.watch(labServicesCartProvider);
  final all = ref.watch(labServicesProvider).value ?? const <LabService>[];
  return [
    for (final service in all)
      if (ids.contains(service.id)) service,
  ];
});

/// Сумма корзины. Считается на клиенте: цены уже пришли вместе с каталогом,
/// и отдельный запрос ради сложения не нужен.
final cartTotalProvider = Provider<int>((ref) {
  var total = 0;
  for (final service in ref.watch(cartServicesProvider)) {
    total += service.price;
  }
  return total;
});

/// Предложения партнёров на текущую корзину.
final labOffersProvider = FutureProvider<List<LabOffer>>((ref) {
  final ids = ref.watch(labServicesCartProvider);
  return ref.watch(labServicesRepositoryProvider).offersFor(ids);
});
