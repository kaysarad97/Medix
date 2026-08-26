import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Поле ввода MedIx с подписью над ним.
///
/// Геометрия снята с `design/Логин Старт.png`: высота поля 66, радиус 18,
/// заливка [AppColors.surfaceWhite], текст отбит слева на 26.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.height = loginFieldHeight,
    this.maxLength,
    this.inputFormatters,
  });

  /// Высота поля на экране логина (`design/Логин Старт.png`).
  static const double loginFieldHeight = 66;

  /// Высота поля в карточках регистрации — там поля ниже
  /// (`design/Создайте профиль.png`, `design/Ваши Данные.png`).
  static const double compactFieldHeight = 59;

  /// Отступ текста от левого края поля.
  static const double _textInset = 26;

  /// Расстояние от подписи до поля.
  static const double _labelGap = 11;

  /// Отбивка иконки-суффикса от правого края поля.
  static const double _suffixInset = 9;

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final double height;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.label),
          const SizedBox(height: _labelGap),
        ],
        SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
              border: hasError
                  ? Border.all(color: AppColors.error, width: 1.5)
                  : null,
            ),
            // Суффикс кладём соседом в Row, а не в InputDecoration.suffixIcon:
            // тот растягивает строку по высоте иконки и уводит текст на 12
            // выше центра поля. Row с центрированием держит и текст, и иконку
            // ровно посередине независимо от их размеров.
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    enabled: enabled,
                    maxLength: maxLength,
                    inputFormatters: inputFormatters,
                    cursorColor: AppColors.accent,
                    style: AppTypography.bodyLg,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      // Счётчик символов ломает фиксированную высоту поля.
                      counterText: '',
                      hintText: hint,
                      hintStyle: AppTypography.placeholder,
                      contentPadding: EdgeInsets.only(
                        left: _textInset,
                        right: suffix != null ? AppSpacing.xs : _textInset,
                      ),
                    ),
                  ),
                ),
                if (suffix != null)
                  // Центр иконки в макете стоит на 33 от правой кромки поля,
                  // при области нажатия 48 это отбивка 9.
                  Padding(
                    padding: const EdgeInsets.only(right: _suffixInset),
                    child: suffix,
                  ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Padding(
            padding: const EdgeInsets.only(left: _textInset),
            child: Text(
              errorText!,
              style: AppTypography.captionMuted.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
