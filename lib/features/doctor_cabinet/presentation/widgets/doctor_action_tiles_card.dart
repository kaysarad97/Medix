import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_home_metrics.dart';

/// Карточка «График работы» / «История записей» + «Аналитика активности» —
/// один `AppCard` на все три, как у пациентской `QuickActionsCard`: два
/// узких тайла в ряд сверху, широкий цветной тайл под ними.
class DoctorActionTilesCard extends StatelessWidget {
  const DoctorActionTilesCard({
    super.key,
    required this.scheduleTitle,
    required this.scheduleSubtitle,
    required this.historyTitle,
    required this.historySubtitle,
    required this.analyticsTitle,
    required this.analyticsSubtitle,
    this.onSchedule,
    this.onHistory,
    this.onAnalytics,
  });

  final String scheduleTitle;
  final String scheduleSubtitle;
  final String historyTitle;
  final String historySubtitle;
  final String analyticsTitle;
  final String analyticsSubtitle;
  final VoidCallback? onSchedule;
  final VoidCallback? onHistory;
  final VoidCallback? onAnalytics;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(DoctorHomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: DoctorHomeMetrics.tileRowHeight,
            child: Row(
              children: [
                Expanded(
                  child: _NarrowTile(
                    title: scheduleTitle,
                    subtitle: scheduleSubtitle,
                    icon: MedixIcon.doctorSchedule,
                    onTap: onSchedule,
                  ),
                ),
                const SizedBox(width: DoctorHomeMetrics.tileGap),
                Expanded(
                  child: _NarrowTile(
                    title: historyTitle,
                    subtitle: historySubtitle,
                    icon: MedixIcon.appointmentHistory,
                    onTap: onHistory,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DoctorHomeMetrics.tilesToWideTile),
          DoctorWideInfoTile(
            title: analyticsTitle,
            subtitle: analyticsSubtitle,
            icon: MedixIcon.planAnalytics,
            background: AppColors.surfaceInfo,
            onTap: onAnalytics,
          ),
        ],
      ),
    );
  }
}

class _NarrowTile extends StatelessWidget {
  const _NarrowTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final MedixIcon icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 13, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.tileTitle),
                    ),
                    AppIconChip(icon: icon),
                  ],
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.tileSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Широкая плитка с иконкой, заголовком и подписью.
///
/// Сама по себе уже выглядит завершённой карточкой (`Material` даёт и
/// заливку, и скругление) — годится и как содержимое чужого `AppCard`
/// (тайл «Аналитика активности» внутри [DoctorActionTilesCard]), и как
/// самостоятельная карточка на главной («Мои сообщения», «Администрация»
/// — у обеих в макете свои скруглённые углы, не общий контейнер).
class DoctorWideInfoTile extends StatelessWidget {
  const DoctorWideInfoTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.background = AppColors.surface,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final MedixIcon icon;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorHomeMetrics.wideTileHeight,
      child: Material(
        color: background,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                AppIconChip(icon: icon),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.tileTitle),
                      const SizedBox(height: 6),
                      Text(subtitle, style: AppTypography.tileSubtitle),
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
