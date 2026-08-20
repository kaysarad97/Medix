import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Верхняя строка внутреннего экрана: стрелка назад, заголовок по центру
/// и необязательный чип справа.
///
/// Замеры по `design/Профиль врача + запись.png`: заголовок центрирован по
/// ширине экрана, а не по остатку между стрелкой и чипом, поэтому строка
/// собрана стопкой, а не рядом.
class ScreenTopBar extends StatelessWidget {
  const ScreenTopBar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.titleColor,
    this.height = defaultHeight,
    this.titleMaxWidth,
  });

  final String title;

  /// Обычно белый, но на «Настройках» в макете заголовок синий.
  final Color? titleColor;
  final VoidCallback? onBack;

  /// Чип города в правом углу. На экране «Ваша запись» его нет.
  final Widget? trailing;

  /// Высота строки. Обычно [defaultHeight], но у «Заявки в
  /// администрацию» заголовок в макете занимает две строки, и строку
  /// приходится делать выше.
  final double height;

  /// Ограничение ширины заголовка. Нужно там, где в макете он переносится
  /// на две строки («Заявка в администрацию»): без ограничения строка
  /// умещается в одну и расходится с макетом.
  final double? titleMaxWidth;

  static const double defaultHeight = 34;

  /// Центр стрелки — 65 от левого края. В макете она заметно вдвинута
  /// внутрь относительно полей экрана.
  static const double backArrowCenterX = 65;
  static const double backArrowSize = 20;

  /// Чип справа кончается на x 423 при ширине макета 440.
  static const double trailingRight = 17;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: titleMaxWidth ?? double.infinity,
              ),
              child: Text(
                title,
                style: titleColor == null
                    ? AppTypography.screenTitle
                    : AppTypography.screenTitle.copyWith(color: titleColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Positioned(
            left: backArrowCenterX - defaultHeight / 2,
            top: 0,
            bottom: 0,
            child: _BackButton(onTap: onBack),
          ),
          if (trailing != null)
            Positioned(
              right: trailingRight,
              top: 0,
              bottom: 0,
              child: Center(child: trailing),
            ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Квадрат по высоте строки: сам глиф в макете 12×10, попасть пальцем
      // в него невозможно.
      width: ScreenTopBar.defaultHeight,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Icon(
              Icons.arrow_back,
              size: ScreenTopBar.backArrowSize,
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
