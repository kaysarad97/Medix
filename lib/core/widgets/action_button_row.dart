import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'icon_chip.dart';

/// Пара кнопок «действие + сообщение».
///
/// Лежит в `core/`, потому что понадобилась второй фиче: в телемедицине это
/// карточка расписания, карточка переноса и экран записи, а в кабинете врача
/// — «Запись с пациентом». Тот же случай, что и с `RatingStars`.
///
/// Кнопки в карточке неравной ширины (188 и 161), а на экране записи —
/// одинаковой, поэтому пропорция задаётся снаружи.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.primary,
    required this.secondary,
    required this.height,
    this.primaryFlex = defaultPrimaryFlex,
    this.secondaryFlex = defaultSecondaryFlex,
  });

  final ActionButtonData primary;
  final ActionButtonData secondary;
  final double height;
  final int primaryFlex;
  final int secondaryFlex;

  /// Ширины кнопок в карточке расписания: 188 и 161 по макету врача.
  static const int defaultPrimaryFlex = 188;
  static const int defaultSecondaryFlex = 161;

  /// Зазор между кнопками — там же.
  static const double gap = 15;

  /// Скругление кнопки: 14 по макетам врача — своё, не из [AppRadius].
  static const BorderRadius radius = BorderRadius.all(Radius.circular(14));

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
          const SizedBox(width: gap),
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
      borderRadius: ActionButtonRow.radius,
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
