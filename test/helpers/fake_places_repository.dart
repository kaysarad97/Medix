import 'package:latlong2/latlong.dart';
import 'package:medix/features/map_search/data/repositories/places_repository.dart';
import 'package:medix/features/map_search/domain/entities/medical_place.dart';

/// Те же места, что у [MockPlacesRepository], но без задержки: таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakePlacesRepository implements PlacesRepository {
  const FakePlacesRepository();

  @override
  Future<List<MedicalPlace>> nearby(LatLng center) async =>
      MockPlacesRepository.mockPlaces;
}
