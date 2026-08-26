import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Круглый чекбокс согласия.
///
/// Геометрия из `design/Язык и пуш увед.png`: круг 24×24, залит
/// [AppColors.surfaceWhite]. Отмеченного состояния в макетах нет —
/// показаны только пустые кружки, поэтому заливка [AppColors.brandIndigo]
/// с белой галочкой добавлена нами.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  static const double size = 24;

  /// Область нажатия шире самого кружка — 24 px мало для пальца.
  static const double _tapTarget = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: semanticLabel,
      child: SizedBox(
        width: _tapTarget,
        height: _tapTarget,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onChanged(!value),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? AppColors.brandIndigo : AppColors.surfaceWhite,
                ),
                child: value
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textOnPrimary,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
