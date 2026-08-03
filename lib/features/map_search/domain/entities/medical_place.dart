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
class MedicalPlace {
  const MedicalPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.address,
    required this.position,
    this.phone,
  });

  final String id;
  final String name;
  final PlaceKind kind;

  /// Улица и дом одной строкой — как придёт из партнёрского API.
  final String address;

  final LatLng position;
  final String? phone;
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
