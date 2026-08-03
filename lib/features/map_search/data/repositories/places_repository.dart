import 'package:latlong2/latlong.dart';

import '../../domain/entities/medical_place.dart';

abstract interface class PlacesRepository {
  /// Учреждения рядом с точкой. Радиус задаёт бэкенд; пока не используется.
  Future<List<MedicalPlace>> nearby(LatLng center);
}

/// Заглушка на время разработки бэкенда.
///
/// Координаты настоящие — это реально существующие адреса в Алматы, взятые
/// с публичных карт. Так метки ложатся на нужные улицы, и по ним видно, что
/// карта работает; когда появится партнёрский API, список поедет оттуда.
class MockPlacesRepository implements PlacesRepository {
  const MockPlacesRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  /// Центр Алматы — с него открывается карта в макете.
  static const LatLng almaty = LatLng(43.2389, 76.8897);

  @override
  Future<List<MedicalPlace>> nearby(LatLng center) async {
    await Future<void>.delayed(_latency);
    return mockPlaces;
  }

  static const List<MedicalPlace> mockPlaces = [
    MedicalPlace(
      id: 'h1',
      name: 'Городская клиническая больница №4',
      kind: PlaceKind.hospital,
      address: 'ул. Папанина, 220',
      position: LatLng(43.2312, 76.8829),
    ),
    MedicalPlace(
      id: 'h2',
      name: 'Центральная городская клиническая больница',
      kind: PlaceKind.hospital,
      address: 'пр. Райымбека, 199',
      position: LatLng(43.2637, 76.9285),
    ),
    MedicalPlace(
      id: 'h3',
      name: 'Городская поликлиника №6',
      kind: PlaceKind.hospital,
      address: 'мкр. Аксай-2, 60',
      position: LatLng(43.2205, 76.8342),
    ),
    MedicalPlace(
      id: 'l1',
      name: 'Олимп',
      kind: PlaceKind.laboratory,
      address: 'пр. Абылай хана, 93/95',
      position: LatLng(43.2547, 76.9432),
    ),
    MedicalPlace(
      id: 'l2',
      name: 'Инвиво',
      kind: PlaceKind.laboratory,
      address: 'ул. Тимирязева, 42',
      position: LatLng(43.2295, 76.9088),
    ),
    MedicalPlace(
      id: 'l3',
      name: 'Интертич',
      kind: PlaceKind.laboratory,
      address: 'ул. Жандосова, 98',
      position: LatLng(43.2178, 76.8721),
    ),
  ];
}
