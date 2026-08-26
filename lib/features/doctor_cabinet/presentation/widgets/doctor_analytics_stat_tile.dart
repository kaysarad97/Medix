import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_analytics_metrics.dart';

/// Плитка показателя — «49 минут» и подпись под ним.
///
/// Две раскраски: в карточке недели плитка голубая с белой подписью-пилюлей,
/// в карточке месяца наоборот — белая плитка с синей пилюлей. Это одна и та
/// же плитка на разном фоне, поэтому флаг, а не два виджета.
class DoctorAnalyticsStatTile extends StatelessWidget {
  const DoctorAnalyticsStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.onLightCard,
    this.showStar = false,
  });

  /// «49 минут», «+0.5», «+20%».
  final String value;

  /// Подпись в пилюле: «средняя длина записи».
  final String label;

  /// Плитка стоит на светлой карточке недели (голубая плитка) или на синей
  /// карточке месяца (белая плитка).
  final bool onLightCard;

  /// Звезда рядом со значением — только у прироста рейтинга.
  final bool showStar;

  @override
  Widget build(BuildContext context) {
    final tileColor = onLightCard
        ? AppColors.accentSoft
        : AppColors.surfaceWhite;
    final pillColor = onLightCard
        ? AppColors.surfaceWhite
        // Пилюля на синей карточке месяца — accent, а не primaryBright:
        // замер по макету даёт 4787FA.
        : AppColors.accent;
    final pillTextColor = onLightCard
        ? AppColors.primaryBright
        : AppColors.textOnPrimary;

    return SizedBox(
      height: DoctorAnalyticsMetrics.statTileHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: AppRadius.allMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: AppTypography.cardItemTitle,
                      ),
                    ),
                  ),
                  if (showStar) ...[
                    const SizedBox(width: 4),
                    const AppIcon(
                      icon: MedixIcon.star,
                      size: 14,
                      color: AppColors.primaryBright,
                    ),
                  ],
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: AppRadius.allSm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTypography.tileSubtitle.copyWith(
                        color: pillTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
