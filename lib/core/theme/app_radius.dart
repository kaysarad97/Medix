import 'package:flutter/widgets.dart';

/// Радиусы скругления MedIx.
abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;

  /// Базовый радиус. Замерен по кривой угла в `design/Логин Старт.png`:
  /// карточка, поле ввода и кнопка — все три ≈ 18.
  static const double md = 18;

  static const double lg = 24;

  /// Полное скругление: прогресс-бар, чипы, аватары.
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));
}
