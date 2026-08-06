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

  /// Рейтинг, часы и контакты — заглушка: у `h1`/`l1` цифры совпадают с
  /// `design/Карточка лаборатории.png` (900 м, 12/22 мин, 19 филиалов),
  /// остальные места просто разнообразят данные, чтобы было на чём проверить
  /// «закрыто», отсутствие WhatsApp/сайта и одиночные (без сети) точки.
  static const List<MedicalPlace> mockPlaces = [
    MedicalPlace(
      id: 'h1',
      name: 'Городская клиническая больница №4',
      kind: PlaceKind.hospital,
      address: 'ул. Папанина, 220',
      position: LatLng(43.2312, 76.8829),
      category: 'Городская больница',
      rating: 4.2,
      openNow: true,
      distanceLabel: '1.2 км',
      todayHours: '8:00 - 20:00',
      weekdayHours: 'Пн-Пт: 8:00 - 20:00',
      weekendHours: 'Сб-Вс: 9:00 - 15:00',
      driveMinutes: 9,
      walkMinutes: 25,
      branchesCount: 1,
      phone: '+7 727 000 00 00',
    ),
    MedicalPlace(
      id: 'h2',
      name: 'Центральная городская клиническая больница',
      kind: PlaceKind.hospital,
      address: 'пр. Райымбека, 199',
      position: LatLng(43.2637, 76.9285),
      category: 'Многопрофильная больница',
      rating: 4.4,
      openNow: true,
      distanceLabel: '3.4 км',
      todayHours: '7:00 - 21:00',
      weekdayHours: 'Пн-Пт: 7:00 - 21:00',
      weekendHours: 'Сб-Вс: 8:00 - 18:00',
      driveMinutes: 14,
      walkMinutes: 48,
      branchesCount: 3,
      phone: '+7 727 000 00 01',
      website: 'cgkb.kz',
    ),
    MedicalPlace(
      id: 'h3',
      name: 'Городская поликлиника №6',
      kind: PlaceKind.hospital,
      address: 'мкр. Аксай-2, 60',
      position: LatLng(43.2205, 76.8342),
      category: 'Поликлиника',
      rating: 4.0,
      openNow: false,
      distanceLabel: '650 м',
      todayHours: '8:00 - 18:00',
      weekdayHours: 'Пн-Пт: 8:00 - 18:00',
      weekendHours: 'Сб: 9:00 - 14:00, Вс: выходной',
      driveMinutes: 5,
      walkMinutes: 12,
      branchesCount: 1,
    ),
    MedicalPlace(
      id: 'l1',
      name: 'Олимп',
      kind: PlaceKind.laboratory,
      address: 'пр. Абылай хана, 93/95',
      position: LatLng(43.2547, 76.9432),
      category: 'Клинико-диагностическая лаборатория',
      rating: 4.6,
      openNow: true,
      distanceLabel: '900 м',
      todayHours: '9:00 - 17:00',
      todayNote: 'приём анализов до 15:00',
      weekdayHours: 'Пн-Пт: 9:00 - 17:00',
      weekendHours: 'Сб-Вс: 9:00 - 14:00',
      driveMinutes: 12,
      walkMinutes: 22,
      branchesCount: 19,
      phone: '+7 700 000 00 00',
      hasWhatsapp: true,
      website: 'olymp-lab.kz',
    ),
    MedicalPlace(
      id: 'l2',
      name: 'Инвиво',
      kind: PlaceKind.laboratory,
      address: 'ул. Тимирязева, 42',
      position: LatLng(43.2295, 76.9088),
      category: 'Медицинская лаборатория',
      rating: 4.7,
      openNow: true,
      distanceLabel: '2.1 км',
      todayHours: '7:30 - 19:00',
      todayNote: 'приём анализов до 17:00',
      weekdayHours: 'Пн-Сб: 7:30 - 19:00',
      weekendHours: 'Вс: 8:00 - 14:00',
      driveMinutes: 8,
      walkMinutes: 20,
      branchesCount: 34,
      phone: '+7 700 000 00 01',
      hasWhatsapp: true,
      website: 'invivo.kz',
    ),
    MedicalPlace(
      id: 'l3',
      name: 'Интертич',
      kind: PlaceKind.laboratory,
      address: 'ул. Жандосова, 98',
      position: LatLng(43.2178, 76.8721),
      category: 'Лаборатория анализов',
      rating: 4.3,
      openNow: false,
      distanceLabel: '4.5 км',
      todayHours: '8:00 - 18:00',
      weekdayHours: 'Пн-Пт: 8:00 - 18:00',
      weekendHours: 'Сб: 9:00 - 15:00, Вс: выходной',
      driveMinutes: 16,
      walkMinutes: 55,
      branchesCount: 7,
      phone: '+7 700 000 00 02',
    ),
  ];
}
