import 'package:flutter/widgets.dart';

/// Размеры экрана звонка.
///
/// Замеры по `design/Видео-звонок.png`, `design/Аудио-звонок.png» и парным
/// экранам «завершен» (все четыре — 440×978, безопасная зона сверху 62, как
/// на остальных экранах телемедицины).
abstract final class CallMetrics {
  static const double screenH = 20;

  /// Верх шапки — тот же отступ, что и на «Ваша Запись»/«О враче».
  static const double topBarTop = 36;

  /// Заголовок → строка таймера.
  static const double topBarToStatus = 8;

  /// «0:36» → «Вызов завершен» вторым слоем, когда звонок сброшен.
  static const double statusLines = 4;

  /// Таймер → большое фото на видео-звонке.
  static const double statusToPhoto = 64;

  /// Высота большого фото на видео-звонке; ширина — на всю карточку.
  static const double videoPhotoHeight = 491;

  /// Фото → подпись с именем.
  static const double photoToName = 17;

  /// Имя → ряд с кнопками управления. Самопросмотр начинается почти
  /// вплотную к имени — по замеру они его касаются, поэтому отступ мал.
  static const double nameToControls = 2;

  /// Диаметр круглой кнопки управления.
  static const double controlSize = 56;

  /// Габариты ромба из четырёх кнопок управления (без самопросмотра).
  static const Size controlsClusterSize = Size(198, 137);

  /// Отступ сверху у боковых кнопок (пауза/чат) ромба — камера сверху и
  /// сброс снизу прижаты к краям, эти две — по центру высоты.
  static const double controlsSideTop = 36;

  /// Самопросмотр (PIP) рядом с ромбом на видео-звонке.
  static const Size selfViewSize = Size(150, 146);

  /// Заголовок → маленькое фото на аудио-звонке (фото и имя центрированы).
  static const double statusToAudioPhoto = 145;

  /// Маленькое фото на аудио-звонке.
  static const Size audioPhotoSize = Size(150, 190);

  /// Фото → имя на аудио-звонке — чуть больше, чем на видео-звонке.
  static const double audioPhotoToName = 25;

  /// Аудио-звонок: имя → ряд кнопок управления — заметно больше, чем на
  /// видео-звонке: там под фото сразу самопросмотр вплотную к кнопкам, а
  /// здесь ряд кнопок остаётся на том же месте экрана, что и на
  /// видео-звонке, просто без самопросмотра рядом.
  static const double audioNameToControls = 229;
}
