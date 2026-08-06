import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/medical_place.dart';

/// Детальная карточка учреждения под сжатой картой.
///
/// Свёрстана по `design/Карточка лаборатории.png` — единственный присланный
/// вариант, для лаборатории; для больниц используется тот же виджет с
/// данными из мока, макета под них отдельно нет. Иконки «на машине»/«пешком»
/// и часов дизайнер не экспортировал — сырые Material `Icon`, тем же
/// приёмом, что иконка корзины/сортировки в «Перечне услуг». Телефон,
/// WhatsApp, метка и звезда — уже подключённые `MedixIcon`.
class PlaceDetailCard extends StatelessWidget {
  const PlaceDetailCard({
    super.key,
    required this.place,
    this.onShowBranches,
    this.onOrderTests,
  });

  final MedicalPlace place;
  final VoidCallback? onShowBranches;
  final VoidCallback? onOrderTests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: AppColors.surface,
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Chip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(
                          icon: MedixIcon.star,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(place.ratingLabel, style: AppTypography.chipLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    child: Text(
                      place.statusLabel,
                      style: AppTypography.chipLabel.copyWith(
                        color: place.openNow
                            ? AppColors.scaleNormal
                            : AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    child: Text(
                      place.distanceLabel,
                      style: AppTypography.chipLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppIconChip(
                    icon: place.kind == PlaceKind.laboratory
                        ? MedixIcon.labTest
                        : MedixIcon.hospital,
                    size: 56,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name, style: AppTypography.titleMd),
                        const SizedBox(height: 2),
                        Text(
                          place.category,
                          style: AppTypography.linkSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          place.address,
                          style: AppTypography.linkSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(place.driveLabel, style: AppTypography.chipLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(place.walkLabel, style: AppTypography.chipLabel),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SubCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: AppTypography.bodyMd,
                              children: [
                                const TextSpan(text: 'Сегодня: '),
                                TextSpan(
                                  text: place.todayHours,
                                  style: TextStyle(
                                    color: place.openNow
                                        ? AppColors.scaleNormal
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (place.todayNote != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              place.todayNote!,
                              style: AppTypography.cardItemMeta,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(place.weekdayHours, style: AppTypography.bodyMd),
                          Text(place.weekendHours, style: AppTypography.bodyMd),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (place.phone != null) ...[
                const SizedBox(height: 12),
                _SubCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Контакты', style: AppTypography.label),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const AppIcon(
                            icon: MedixIcon.doctorCall,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(place.phone!, style: AppTypography.bodyMd),
                        ],
                      ),
                      if (place.hasWhatsapp || place.website != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (place.hasWhatsapp) ...[
                              const AppIcon(
                                icon: MedixIcon.whatsapp,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('WhatsApp', style: AppTypography.linkSmall),
                            ],
                            if (place.hasWhatsapp && place.website != null)
                              const SizedBox(width: 16),
                            if (place.website != null) ...[
                              const Icon(
                                Icons.language,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text('Веб-сайт', style: AppTypography.linkSmall),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (place.branchesCount > 1) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: onShowBranches,
                  borderRadius: AppRadius.allSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const AppIcon(
                          icon: MedixIcon.locationPin,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Показать все филиалы (${place.branchesCount})',
                            style: AppTypography.bodyMd,
                          ),
                        ),
                        const AppIcon(
                          icon: MedixIcon.chevronRight,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (place.kind == PlaceKind.laboratory) ...[
          const SizedBox(height: 16),
          Material(
            color: AppColors.accentSofter,
            borderRadius: AppRadius.allMd,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOrderTests,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppIcon(
                      icon: MedixIcon.labTest,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Сдать анализы в КДЛ «${place.name}»',
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Мелкая пилюля-чип: рейтинг, статус, дистанция, время в пути.
class _Chip extends StatelessWidget {
  const _Chip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: child,
      ),
    );
  }
}

/// Вложенная белая карточка внутри серой — часы работы, контакты.
class _SubCard extends StatelessWidget {
  const _SubCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceWhite,
      borderRadius: AppRadius.allSm,
      padding: const EdgeInsets.all(13),
      shadows: const [],
      child: child,
    );
  }
}
