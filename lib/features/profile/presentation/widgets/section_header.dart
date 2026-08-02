import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'profile_metrics.dart';

/// Строка-заголовок карточки на экране профиля: кружок с иконкой, название
/// и шеврон-ссылка справа.
///
/// Одинакова у «Мед-карты», «Предыдущих процедур» и «Ваших анализов».
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
    this.iconBackground = AppColors.surfaceInfo,
  });

  final MedixIcon icon;
  final String title;
  final VoidCallback? onTap;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.sectionHeaderHeight,
      child: Row(
        children: [
          AppIconChip(
            icon: icon,
            size: ProfileMetrics.sectionIconSize,
            background: iconBackground,
            foreground: AppColors.primary,
          ),
          const SizedBox(width: ProfileMetrics.sectionIconToTitle),
          Expanded(
            child: Text(
              title,
              style: AppTypography.sectionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null)
            const AppIcon(
              icon: MedixIcon.chevronRight,
              size: ProfileMetrics.chevronSize,
              color: AppColors.primary,
            ),
        ],
      ),
    );
  }
}
