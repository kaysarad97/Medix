import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_checkbox.dart';

/// Кружок согласия с подписью справа.
///
/// Замеры по `design/Язык и пуш увед.png`: кружок на 53, текст на 88.
class ConsentRow extends StatelessWidget {
  const ConsentRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 43, right: AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            // Кружок 24 сидит по центру зоны нажатия 44×44, то есть с
            // отбивкой 10 со всех сторон. По горизонтали это уже учтено
            // в padding слева (43 + 10 = 53, как в макете), а по вертикали
            // нужно поднять, чтобы кружок встал вровень с первой строкой.
            offset: const Offset(0, -10),
            child: AppCheckbox(
              value: value,
              onChanged: onChanged,
              semanticLabel: text,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              behavior: HitTestBehavior.opaque,
              child: Text(text, style: AppTypography.consent),
            ),
          ),
        ],
      ),
    );
  }
}
