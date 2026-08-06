import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import 'home_metrics.dart';

/// Карточка быстрых действий: горизонтальный список плиток и одна широкая
/// под ним.
class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({
    super.key,
    this.onLabTests,
    this.onMessages,
    this.onDoctorAppointment,
    this.onFindFacility,
  });

  final VoidCallback? onLabTests;
  final VoidCallback? onMessages;
  final VoidCallback? onDoctorAppointment;
  final VoidCallback? onFindFacility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(HomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: HomeMetrics.actionTileHeight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionTile(
                    width: HomeMetrics.actionTileWideWidth,
                    title: l10n.quickActionLabTestsTitle,
                    subtitle: l10n.quickActionLabTestsSubtitle,
                    icon: MedixIcon.labTest,
                    onTap: onLabTests,
                  ),
                  const SizedBox(width: HomeMetrics.actionTileGap),
                  _ActionTile(
                    width: HomeMetrics.actionTileWideWidth,
                    title: l10n.quickActionMessagesTitle,
                    subtitle: l10n.quickActionMessagesSubtitle,
                    icon: MedixIcon.attachment,
                    onTap: onMessages,
                  ),
                  const SizedBox(width: HomeMetrics.actionTileGap),
                  _ActionTile(
                    width: HomeMetrics.actionTileNarrowWidth,
                    title: l10n.quickActionDoctorTitle,
                    subtitle: l10n.quickActionDoctorSubtitle,
                    icon: MedixIcon.doctorCall,
                    onTap: onDoctorAppointment,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: HomeMetrics.tilesToWideTile),
          _WideTile(
            title: l10n.quickActionFacilityTitle,
            subtitle: l10n.quickActionFacilitySubtitle,
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
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final MedixIcon icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
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
