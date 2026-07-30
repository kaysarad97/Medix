import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Размер основной кнопки.
enum PrimaryButtonSize {
  /// Крупная кнопка экрана логина: высота 70, надпись 20.
  large,

  /// Кнопка «Далее» на остальных экранах: высота 55, надпись 17.
  ///
  /// В макетах она не на всю ширину — 330 по центру. Ширину задаёт
  /// родитель, кнопка занимает всё доступное место.
  medium,
}

/// Основная кнопка MedIx.
///
/// По умолчанию заливка — [AppColors.primaryBright], как на большинстве
/// экранов. Логин в макетах использует более тёмный [AppColors.primary],
/// поэтому цвет вынесен в параметр.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PrimaryButtonSize.medium,
    this.color = AppColors.primaryBright,
    this.trailingIcon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonSize size;
  final Color color;
  final IconData? trailingIcon;
  final bool isLoading;

  double get _height => size == PrimaryButtonSize.large ? 70 : 55;

  /// Ширина кнопки «Далее» в макетах регистрации.
  static const double mediumWidth = 330;

  TextStyle get _textStyle => size == PrimaryButtonSize.large
      ? AppTypography.buttonLg
      : AppTypography.buttonMd;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      height: _height,
      width: double.infinity,
      child: Material(
        color: isEnabled ? color : color.withValues(alpha: 0.45),
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: _textStyle),
                      if (trailingIcon != null) ...[
                        // Замер по `design/Ваши Данные.png`: между надписью
                        // и стрелкой 19, сама стрелка ~13 в ширину.
                        const SizedBox(width: 18),
                        Icon(
                          trailingIcon,
                          size: 16,
                          color: AppColors.textOnPrimary,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
