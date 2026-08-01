import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import 'doctor_metrics.dart';

/// Пара кнопок «действие + сообщение», которая встречается на макетах врача
/// трижды: в карточке расписания, в карточке переноса и на экране записи.
///
/// Кнопки в карточке неравной ширины (188 и 161), а на экране записи —
/// одинаковой, поэтому пропорция задаётся снаружи.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.primary,
    required this.secondary,
    required this.height,
    this.primaryFlex = DoctorMetrics.cardActionLeftFlex,
    this.secondaryFlex = DoctorMetrics.cardActionRightFlex,
  });

  final ActionButtonData primary;
  final ActionButtonData secondary;
  final double height;
  final int primaryFlex;
  final int secondaryFlex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        // Иначе кнопки съёжатся до высоты своего текста и встанут по центру
        // строки вместо того, чтобы занять её целиком.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: primaryFlex,
            child: _ActionButton(data: primary, filled: true),
          ),
          const SizedBox(width: DoctorMetrics.actionGap),
          Expanded(
            flex: secondaryFlex,
            child: _ActionButton(data: secondary, filled: false),
          ),
        ],
      ),
    );
  }
}

/// Содержимое одной кнопки.
class ActionButtonData {
  const ActionButtonData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final MedixIcon icon;

  /// Крупная надпись. «Создать запись», «Сообщение».
  final String title;

  /// Подпись под ней. «Видео-звонок», «Чат с врачом».
  final String subtitle;

  final VoidCallback? onTap;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.data, required this.filled});

  final ActionButtonData data;

  /// Залитая синим или белая.
  final bool filled;

  /// Кружок иконки: 30 в диаметре, 13 от левого края кнопки.
  static const double iconSize = 30;
  static const double paddingLeft = 13;
  static const double iconToText = 10;

  @override
  Widget build(BuildContext context) {
    final titleColor = filled ? AppColors.textOnPrimary : AppColors.textPrimary;
    final subtitleColor = filled
        ? AppColors.accentSofter
        : AppColors.primaryBright;

    return Material(
      color: filled ? AppColors.primaryBright : AppColors.surfaceWhite,
      borderRadius: DoctorMetrics.allRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: paddingLeft, right: 8),
          child: Row(
            children: [
              AppIconChip(
                icon: data.icon,
                size: iconSize,
                background: AppColors.accentSofter,
                foreground: AppColors.primaryBright,
              ),
              const SizedBox(width: iconToText),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: AppTypography.actionTitle.copyWith(
                        color: titleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: AppTypography.tileSubtitle.copyWith(
                        color: subtitleColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
