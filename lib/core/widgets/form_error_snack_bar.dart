import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Показывает ошибку, не привязанную к конкретному полю: отказ сервера,
/// отсутствие сети.
///
/// Красный тут не используется — в макетах цвета ошибки нет, статус
/// передаётся текстом. Инлайн-ошибки полей — другое дело, там без цвета
/// не обойтись, см. [AppColors.error].
void showFormErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTypography.bodyMd.copyWith(color: AppColors.textOnPrimary),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
