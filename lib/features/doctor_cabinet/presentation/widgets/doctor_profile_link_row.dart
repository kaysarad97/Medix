import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_profile_metrics.dart';

/// Строка-ссылка на «Ваш Профиль»: «Ваши сертификаты», «Отзывы о Вас»,
/// «Запросы в администрацию» (последняя — только у врача от клиники).
///
/// Форма — как у пациентских настроек (`_RowCard`), не импортируется:
/// та лежит в `features/profile`, чужой фиче.
class DoctorProfileLinkRow extends StatelessWidget {
  const DoctorProfileLinkRow({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final MedixIcon icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorProfileMetrics.linkRowHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                AppIconChip(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.tileTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
