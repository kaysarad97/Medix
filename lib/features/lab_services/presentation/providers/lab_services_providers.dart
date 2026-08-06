import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/lab_services_repository.dart';
import '../../domain/entities/lab_service.dart';

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
