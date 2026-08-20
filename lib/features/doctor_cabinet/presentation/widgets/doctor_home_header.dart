import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_home_metrics.dart';

/// Аватар врача и чип уведомлений — форма один в один с пациентской
/// `HomeHeader`, но лежит в своей фиче: приватные виджеты между фичами не
/// шарятся.
class DoctorHomeHeader extends StatelessWidget {
  const DoctorHomeHeader({
    super.key,
    required this.unreadCount,
    this.avatarUrl,
    this.onAvatarTap,
    this.onNotificationsTap,
  });

  final int unreadCount;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationsTap;

  static const double chipHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorHomeMetrics.screenH,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: SizedBox(
              width: DoctorHomeMetrics.avatarSize,
              height: DoctorHomeMetrics.avatarSize,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: avatarUrl == null
                    ? const SizedBox.shrink()
                    : ClipOval(
                        child: Image.network(avatarUrl!, fit: BoxFit.cover),
                      ),
              ),
            ),
          ),
          _NotificationsChip(count: unreadCount, onTap: onNotificationsTap),
        ],
      ),
    );
  }
}

class _NotificationsChip extends StatelessWidget {
  const _NotificationsChip({required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: DoctorHomeHeader.chipHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(icon: MedixIcon.notifications, size: 22),
                const SizedBox(width: 6),
                Text('$count', style: AppTypography.sectionTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
