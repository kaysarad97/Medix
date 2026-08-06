import 'package:latlong2/latlong.dart';

/// Что за учреждение. Определяет и метку на карте, и вкладку фильтра.
enum PlaceKind {
  hospital('Больницы'),
  laboratory('Лаборатории');

  const PlaceKind(this.tabLabel);

  /// Подпись на переключателе над картой.
  final String tabLabel;
}

/// Больница или лаборатория на карте.
///
/// Поля детальной карточки (`design/Карточка лаборатории.png`) — рейтинг,
/// часы работы, контакты — required, а не с дефолтами по умолчанию: как у
/// `Doctor`, у каждого мок-места они разные, задаются явно в
/// `MockPlacesRepository`.
class MedicalPlace {
  const MedicalPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    required this.position,
    required this.category,
    required this.rating,
    required this.openNow,
    required this.distanceLabel,
    required this.todayHours,
    required this.weekdayHours,
    required this.weekendHours,
    required this.driveMinutes,
    required this.walkMinutes,
    required this.branchesCount,
    this.todayNote,
    this.phone,
    this.hasWhatsapp = false,
    this.website,
  });

  final String id;
  final String name;
  final PlaceKind kind;

  /// Улица и дом одной строкой — как придёт из партнёрского API.
  final String address;

  final LatLng position;

  /// Тип учреждения одной строкой. «Клинико-диагностическая лаборатория».
  final String category;

  /// Средняя оценка, 0…5. В чипе — с одним знаком: «4.5».
  final double rating;

  final bool openNow;

  /// «900 м» — геолокации нет, дистанция мок-строкой, не числом.
  final String distanceLabel;

  /// «9:00 - 17:00».
  final String todayHours;

  /// «приём анализов до 15:00». Есть не у всех учреждений — `null` прячет
  /// строку целиком.
  final String? todayNote;

  /// «Пн-Пт: 9:00 - 17:00».
  final String weekdayHours;

  /// «Сб-Вс: 9:00 - 14:00».
  final String weekendHours;

  final int driveMinutes;
  final int walkMinutes;

  /// Сколько филиалов у сети. 1 — своих филиалов нет, строка «Показать все
  /// филиалы» на карточке не рисуется.
  final int branchesCount;

  final String? phone;
  final bool hasWhatsapp;
  final String? website;

  /// Текст чипа рейтинга: «4.5».
  String get ratingLabel => rating.toStringAsFixed(1);

  String get statusLabel => openNow ? 'Открыто' : 'Закрыто';

  String get driveLabel => '$driveMinutes мин';

  String get walkLabel => '$walkMinutes мин';
}

/// Что показано на карте: одно из двух или всё сразу.
///
/// В макете `Поиск (карта).png` подсвечены обе вкладки и видны оба типа
/// меток, а на `Поиск (карта) больницы.png` — только больницы. То есть
/// вкладки не переключают, а включают и выключают слой.
class PlaceFilter {
  const PlaceFilter({this.hospitals = true, this.laboratories = true});

  final bool hospitals;
  final bool laboratories;

  bool includes(PlaceKind kind) => switch (kind) {
    PlaceKind.hospital => hospitals,
    PlaceKind.laboratory => laboratories,
  };

  bool isOn(PlaceKind kind) => includes(kind);

  /// Выключить последний включённый слой нельзя: пустая карта не сообщает
  /// пользователю ничего, а вернуть слой он может только тем же нажатием.
  PlaceFilter toggled(PlaceKind kind) {
    final next = switch (kind) {
      PlaceKind.hospital => PlaceFilter(
        hospitals: !hospitals,
        laboratories: laboratories,
      ),
      PlaceKind.laboratory => PlaceFilter(
        hospitals: hospitals,
        laboratories: !laboratories,
      ),
    };
    return next.hospitals || next.laboratories ? next : this;
  }
}
