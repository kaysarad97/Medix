import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'home_metrics.dart';

/// «Загрузить анализы» — широкая голубая карточка с плотной иконкой слева.
class UploadAnalysesCard extends StatelessWidget {
  const UploadAnalysesCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeMetrics.uploadCardHeight,
      child: Material(
        color: AppColors.accentSofter,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeMetrics.cardPadding,
            ),
            child: Row(
              children: [
                const AppIconChip(
                  icon: MedixIcon.uploadAnalyses,
                  background: AppColors.primaryBright,
                  foreground: AppColors.textOnPrimary,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Загрузить анализы', style: AppTypography.tileTitle),
                      const SizedBox(height: 4),
                      Text(
                        'ИИ-интерпретация',
                        style: AppTypography.tileSubtitle,
                      ),
                    ],
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
