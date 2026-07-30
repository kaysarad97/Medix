import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Тени MedIx.
abstract final class AppShadows {
  /// Тень карточки формы.
  ///
  /// Подобрана под замеренный спад яркости вокруг карточки в
  /// `design/Логин Старт.png`: под нижней кромкой затемнение ≈ 19 %,
  /// исчезает через 7 px; сбоку ≈ 9 %, исчезает через 4 px.
  static const List<BoxShadow> card = [
    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
  ];
}
