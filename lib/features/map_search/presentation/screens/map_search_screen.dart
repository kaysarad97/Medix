import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../data/repositories/places_repository.dart';
import '../../domain/entities/medical_place.dart';
import '../providers/map_providers.dart';
import '../widgets/medix_map.dart';

/// «Больницы и лаборатории рядом» — свёрстан по `design/Поиск (карта).png`.
///
/// Три макета поиска отличаются только набором меток: на общем видны оба
/// типа, на `Поиск (карта) больницы.png` — одни больницы. Поэтому экран
/// один, а вкладки включают и выключают слои.
class MapSearchScreen extends ConsumerWidget {
  const MapSearchScreen({super.key, this.showTiles = true, this.onPlaceTap});

  /// Прокидывается в карту: в тестах тайлы не грузим, сети там нет.
  final bool showTiles;

  final ValueChanged<MedicalPlace>? onPlaceTap;

  /// Замеры по макету: чипы y 164…205, карта 233…939 при полях x 26…414.
  static const double titleTop = 30;
  static const double tabsHeight = 42;
  static const double tabsGap = 12;
  static const double tabsToMap = 28;
  static const double screenH = 26;
  static const double mapBottom = 17;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(placeFilterProvider);
    final places = ref.watch(visiblePlacesProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: titleTop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: screenH),
              child: Row(
                children: [
                  _BackButton(onTap: () => Navigator.of(context).maybePop()),
                  Expanded(
                    child: Text(
                      'Больницы и\nлаборатории рядом',
                      textAlign: TextAlign.center,
                      style: AppTypography.screenTitle,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: screenH),
              child: Row(
                children: [
                  for (final kind in PlaceKind.values) ...[
                    if (kind != PlaceKind.values.first)
                      const SizedBox(width: tabsGap),
                    Expanded(
                      child: _KindTab(
                        kind: kind,
                        selected: filter.isOn(kind),
                        onTap: () =>
                            ref.read(placeFilterProvider.notifier).toggle(kind),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: tabsToMap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  screenH,
                  0,
                  screenH,
                  mapBottom,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.allSm,
                  child: MedixMap(
                    center: MockPlacesRepository.almaty,
                    places: places,
                    showTiles: showTiles,
                    onPlaceTap: onPlaceTap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Вкладка-переключатель слоя меток.
class _KindTab extends StatelessWidget {
  const _KindTab({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final PlaceKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MapSearchScreen.tabsHeight,
      child: Material(
        color: selected ? AppColors.accentSofter : AppColors.surfaceWhite,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allPill,
          side: const BorderSide(color: AppColors.primaryBright),
        ),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                icon: kind == PlaceKind.hospital
                    ? MedixIcon.hospital
                    : MedixIcon.labTest,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  kind.tabLabel,
                  style: AppTypography.bodyMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Icon(
            Icons.arrow_back,
            size: 20,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}
