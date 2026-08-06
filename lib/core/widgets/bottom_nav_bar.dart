import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import 'icon_chip.dart';

/// Нижняя навигация: Домой / Карта / Чаты / Профиль.
///
/// Свёрстан по `design/bottom navigation.png`; размеры и цвета сверены по
/// `design/Главная.png` (компонент в контексте целого экрана надёжнее
/// изолированного экспорта). Плавающая белая таблетка 420×72 с полями по
/// 10 от краёв экрана, четыре равные вкладки. У активной — плашка
/// [AppColors.accentSoft] под глифом [AppColors.primaryBright]; у
/// остальных — просто глиф [AppColors.accent] на 71% непрозрачности, как
/// зашито в самих SVG дизайнера.
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double height = 72;
  static const double sideMargin = 10;
  static const double chipWidth = 78;
  static const double chipHeight = 48;
  static const double iconSize = 26;

  static const _tabs = [
    MedixIcon.navHome,
    MedixIcon.navMap,
    MedixIcon.navChats,
    MedixIcon.navProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: sideMargin),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
          boxShadow: AppShadows.card,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _Tab(
                    icon: _tabs[i],
                    active: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.active, required this.onTap});

  final MedixIcon icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.allLg,
        onTap: onTap,
        child: Center(
          child: SizedBox(
            width: BottomNavBar.chipWidth,
            height: BottomNavBar.chipHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: active ? AppColors.accentSoft : Colors.transparent,
                borderRadius: AppRadius.allLg,
              ),
              child: Center(
                child: AppIcon(
                  icon: icon,
                  size: BottomNavBar.iconSize,
                  color: active
                      ? AppColors.primaryBright
                      : AppColors.accent.withValues(alpha: 0.71),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
