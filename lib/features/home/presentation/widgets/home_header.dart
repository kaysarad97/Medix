import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'home_metrics.dart';

/// Аватар пользователя и чип уведомлений.
///
/// Замеры по `design/Главная.png`.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.unreadCount,
    this.avatarUrl,
    this.onAvatarTap,
    this.onNotificationsTap,
  });

  final int unreadCount;

  /// Фото пользователя. Приходит с бэкенда; пока пусто — рисуем подложку.
  final String? avatarUrl;

  final VoidCallback? onAvatarTap;
  final VoidCallback? onNotificationsTap;

  static const double avatarSize = 60;
  static const double chipHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeMetrics.screenH),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: SizedBox(
              width: avatarSize,
              height: avatarSize,
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
          height: HomeHeader.chipHeight,
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
