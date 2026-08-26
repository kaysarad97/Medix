import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'icon_chip.dart';

/// Строка-заголовок карточки: кружок с иконкой, название и шеврон-ссылка
/// справа.
///
/// Одинакова у «Мед-карты», «Предыдущих процедур», «Ваших анализов» и
/// «Моей Семьи» — то есть нужна и профилю, и главной, поэтому лежит в
/// общих виджетах, а не внутри фичи.
///
/// Размеры замерены по `design/Профиль.png`: кружок иконки 48, шеврон 14,
/// высота строки 50.
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

  static const double _height = 50;
  static const double _iconSize = 48;
  static const double _iconToTitle = 11;
  static const double _chevronSize = 14;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: _height,
      child: Row(
        children: [
          AppIconChip(
            icon: icon,
            size: _iconSize,
            background: iconBackground,
            foreground: AppColors.primary,
          ),
          const SizedBox(width: _iconToTitle),
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
              size: _chevronSize,
              color: AppColors.primary,
            ),
        ],
      ),
    );

    if (onTap == null) return row;

    // Нажимается вся строка, а не только шеврон: в макете это одна ссылка
    // целиком, да и попасть пальцем в стрелку 14 px трудно. `opaque` нужен,
    // чтобы срабатывал и пустой промежуток между названием и шевроном.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}
