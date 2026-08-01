import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'home_metrics.dart';

/// Карточка быстрых действий: две плитки в ряд и одна широкая под ними.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    super.key,
    this.onLabTests,
    this.onDoctorAppointment,
    this.onFindFacility,
  });

  final VoidCallback? onLabTests;
  final VoidCallback? onDoctorAppointment;
  final VoidCallback? onFindFacility;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(HomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: HomeMetrics.actionTileHeight,
            child: Row(
              children: [
                Expanded(
                  flex: HomeMetrics.actionTileLeftFlex,
                  child: _ActionTile(
                    title: 'Сдать\nанализы',
                    subtitle: 'в партнерских лабораториях',
                    icon: MedixIcon.labTest,
                    onTap: onLabTests,
                  ),
                ),
                const SizedBox(width: HomeMetrics.actionTileGap),
                Expanded(
                  flex: HomeMetrics.actionTileRightFlex,
                  child: _ActionTile(
                    title: 'Запись\nк врачу',
                    subtitle: 'в удобное для Вас время',
                    icon: MedixIcon.doctorCall,
                    onTap: onDoctorAppointment,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HomeMetrics.tilesToWideTile),
          _WideTile(
            title: 'Найти лабораторию или\nбольницу',
            subtitle: 'карта и сравнение цен',
            icon: MedixIcon.mapSearch,
            onTap: onFindFacility,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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

class _WideTile extends StatelessWidget {
  const _WideTile({
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
    return SizedBox(
      height: HomeMetrics.wideTileHeight,
      child: Material(
        color: AppColors.surfaceInfo,
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
