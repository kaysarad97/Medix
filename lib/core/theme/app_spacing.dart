/// Шкала отступов MedIx.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Горизонтальные поля экрана.
  ///
  /// Замерено по кнопке «Войти»: x 20…419 при ширине макета 440.
  static const double screenH = 20;

  /// Дополнительный отступ карточки формы относительно полей экрана.
  ///
  /// Карточка на логине уже кнопки: x 35…404, то есть [screenH] + 15.
  static const double formCardH = 35;
}
