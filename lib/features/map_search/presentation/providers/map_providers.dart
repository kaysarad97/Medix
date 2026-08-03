import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/places_repository.dart';
import '../../domain/entities/medical_place.dart';

final placesRepositoryProvider = Provider<PlacesRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockPlacesRepository(),
);

final nearbyPlacesProvider = FutureProvider<List<MedicalPlace>>(
  (ref) =>
      ref.watch(placesRepositoryProvider).nearby(MockPlacesRepository.almaty),
);

/// Какие слои меток включены.
final placeFilterProvider = NotifierProvider<PlaceFilterNotifier, PlaceFilter>(
  PlaceFilterNotifier.new,
);

class PlaceFilterNotifier extends Notifier<PlaceFilter> {
  @override
  PlaceFilter build() => const PlaceFilter();

  void toggle(PlaceKind kind) => state = state.toggled(kind);
}

/// Метки, которые видно с учётом фильтра.
final visiblePlacesProvider = Provider<List<MedicalPlace>>((ref) {
  final places = ref.watch(nearbyPlacesProvider).value ?? const [];
  final filter = ref.watch(placeFilterProvider);
  return places.where((place) => filter.includes(place.kind)).toList();
});
