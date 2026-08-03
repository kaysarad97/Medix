import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/medical_place.dart';

/// Карта с метками учреждений.
///
/// Тайлы берутся у OpenStreetMap: он не требует ключа API, а ключей ни от
/// Google, ни от Яндекса у проекта пока нет. Слой подписан отдельным
/// виджетом — этого требуют правила OSM, без ссылки на источник тайлы
/// использовать нельзя.
///
/// Смена поставщика — это замена [TileLayer] в этом файле, экран и метки
/// остаются как есть.
class MedixMap extends StatelessWidget {
  const MedixMap({
    super.key,
    required this.center,
    required this.places,
    this.onPlaceTap,
    this.showTiles = true,
  });

  final LatLng center;
  final List<MedicalPlace> places;
  final ValueChanged<MedicalPlace>? onPlaceTap;

  /// Загружать тайлы.
  ///
  /// В тестах выключается: тайлы тянутся по сети, а виджет-тест сети не
  /// имеет — вместо карты получались бы пустые квадраты, а голден стал бы
  /// зависеть от того, что успело докачаться.
  final bool showTiles;

  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Масштаб подобран так, чтобы все метки заглушки попали в кадр целиком:
  /// они разбросаны от Аксая до Райымбека, и на более крупном масштабе
  /// крайние обрезаются рамкой.
  static const double initialZoom = 11.6;

  static const double markerSize = 30;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: initialZoom,
            interactionOptions: const InteractionOptions(
              // Поворот выключен: карта в макете строго по северу, а
              // случайный разворот двумя пальцами сбивает чтение улиц.
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            if (showTiles)
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'kz.medix.app',
              ),
            MarkerLayer(
              markers: [
                for (final place in places)
                  Marker(
                    point: place.position,
                    width: markerSize,
                    height: markerSize,
                    child: _PlaceMarker(
                      place: place,
                      onTap: () => onPlaceTap?.call(place),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Positioned(right: 6, bottom: 4, child: _Attribution()),
      ],
    );
  }
}

/// Метка на карте: синий кружок с глифом внутри.
class _PlaceMarker extends StatelessWidget {
  const _PlaceMarker({required this.place, this.onTap});

  final MedicalPlace place;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primaryBright,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textOnPrimary, width: 2),
        ),
        child: Center(
          child: AppIcon(
            icon: place.kind == PlaceKind.hospital
                ? MedixIcon.hospital
                : MedixIcon.labTest,
            size: 15,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

/// Ссылка на источник тайлов. Требование лицензии OpenStreetMap.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '© OpenStreetMap',
          style: AppTypography.cardItemMeta.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
