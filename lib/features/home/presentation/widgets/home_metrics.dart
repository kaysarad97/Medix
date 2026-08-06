import 'package:flutter/widgets.dart';

/// Размеры главного экрана, снятые с `design/Главная.png` (440×1299).
///
/// Собраны в одном месте: экран состоит из однотипных карточек, и разъезд
/// одной цифры виден сразу во всех.
abstract final class HomeMetrics {
  /// Все карточки идут по одной сетке: x 21…418.
  static const double screenH = 21;

  /// Внутренние поля карточки: содержимое 34…405.
  static const double cardPadding = 13;

  /// Верх аватара при безопасной зоне 62.
  static const double headerTop = 23;

  /// Шапка → строка приветствия 167.
  static const double headerToGreeting = 11;

  /// Приветствие 167…240 → поле поиска 278.
  static const double greetingToSearch = 34;

  /// Высота поля «Опишите Ваши симптомы»: 278…331.
  static const double searchHeight = 54;

  /// Поле поиска → карточка действий 362.
  static const double searchToActions = 31;

  /// Расстояние между карточками верхнего уровня.
  static const double cardGap = 24;

  /// Плитки быстрых действий: 375…469.
  static const double actionTileHeight = 95;

  /// Зазор между плитками в горизонтальном списке.
  static const double actionTileGap = 14;

  /// «Сдать анализы» и «Мои сообщения» — заголовок в два слова, нужна
  /// более широкая плитка: 197.
  static const double actionTileWideWidth = 197;

  /// «Запись к врачу» — 165, как в старой раскладке из двух плиток в ряд.
  static const double actionTileNarrowWidth = 165;

  /// Широкая плитка «Найти лабораторию или больницу»: 487…582.
  static const double wideTileHeight = 96;

  /// Плитки → широкая плитка.
  static const double tilesToWideTile = 17;

  /// Карточка врача в карусели: 141 в ширину, 88 в высоту, шаг 162.
  static const double doctorCardWidth = 141;
  static const double doctorCardHeight = 88;
  static const double doctorCardGap = 21;

  /// Заголовок карточки врачей → карусель.
  static const double doctorsTitleToList = 21;

  /// Карточка «Загрузить анализы»: 807…880.
  static const double uploadCardHeight = 74;

  /// Строка предстоящей записи: 1080…1145.
  static const double appointmentRowHeight = 66;
  static const double appointmentRowGap = 20;

  /// Пилюля с датой: 58×38.
  static const Size datePillSize = Size(58, 38);
}
