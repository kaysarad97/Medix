import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_metrics.dart';

/// Чип города в правом углу шапки: «Алматы» с меткой на карте.
class CityChip extends StatelessWidget {
  const CityChip({super.key, required this.city, this.onTap});

  final String city;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.cityChipHeight,
      child: Material(
        color: AppColors.surfaceChip,
        borderRadius: AppRadius.allPill,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  icon: MedixIcon.locationPin,
                  size: 12,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  city,
                  // Мельче остальных чипов: «Алматы» в макете 44 в ширину.
                  style: AppTypography.chipLabel.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
