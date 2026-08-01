import 'package:flutter/widgets.dart';

/// Размеры экранов врача, снятые с `design/Профиль врача + запись.png`
/// (440×1010) и `design/Ваша Запись.png` (440×978).
///
/// Оба макета нарисованы на одной сетке: шапка врача и карточка расписания
/// на них совпадают до пикселя (сдвиги внутри карточки — +19, +68, +113,
/// +213, +265 от её верха на обоих экранах). Поэтому замеры общие.
abstract final class DoctorMetrics {
  /// Поля экрана: карточки идут x 20…420.
  static const double screenH = 20;

  /// Радиус карточек и пилюль на этих макетах.
  ///
  /// НЕ СОВПАДАЕТ СО ШКАЛОЙ `AppRadius`. Замер по спаду верхней строки даёт
  /// 13–14 и для карточек, и для слотов, и для кнопок — то есть между
  /// `sm` (12) и `md` (18), на которых свёрстаны экраны авторизации.
  /// Оставлено как в макете; расхождение шкалы требует решения дизайнера.
  static const double radius = 14;

  static const BorderRadius allRadius = BorderRadius.all(Radius.circular(14));

  // ─── Верхняя строка ────────────────────────────────────────────────────

  /// Стрелка «назад»: глиф 12×10 с центром на x 65, y 112.
  ///
  /// Отступ слева именно такой, а не по полям экрана: в макете стрелка
  /// заметно вдвинута внутрь.
  static const double backArrowCenterX = 65;
  static const double backArrowSize = 20;

  /// Правое поле верхней строки: чип города кончается на x 423.
  static const double topBarRight = 17;

  /// Верхняя строка относительно безопасной зоны (62 на макете):
  /// центр строки на y 115.
  static const double topBarTop = 36;
  static const double topBarHeight = 34;

  /// Чип города «Алматы»: 77×28.
  static const double cityChipHeight = 28;

  /// Верхняя строка → фотография врача (132 → 150).
  static const double topBarToHeader = 18;

  // ─── Шапка врача ───────────────────────────────────────────────────────

  /// Фотография-вырезка: x 23…160, y 150…305.
  static const double photoLeft = 23;
  static const double photoTop = 150;
  static const Size photoSize = Size(137, 155);

  /// Текстовая колонка справа от фото начинается на x 176.
  static const double infoLeft = 176;

  /// Чипы рейтинга и стажа: y 162…195, высота 34.
  static const double chipsTop = 162;
  static const double chipHeight = 34;
  static const double chipGap = 13;

  /// Внутренние поля чипов: «4.5» занимает 69 в ширину, «Стаж 10 лет» — 108.
  static const double chipPaddingH = 14;

  /// Чипы → имя врача (196 → 211 по краске).
  static const double chipsToName = 9;

  /// Имя → специальность.
  static const double nameToSpecialty = 6;

  /// Специальность → строка клиники.
  static const double specialtyToClinic = 5;

  // ─── Карточка расписания ───────────────────────────────────────────────

  /// Карточка начинается на y 315 (профиль) и 523 (запись); в обоих
  /// случаях это 10 от нижней кромки фотографии.
  static const double photoToCard = 10;

  /// Поля карточки. По горизонтали 19 (кнопка внутри: x 39…400 при
  /// карточке 20…420), по вертикали 13.
  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 19,
    vertical: 13,
  );

  /// Заголовок карточки → «Июль, 2026».
  static const double titleToMonth = 27;

  /// «Июль, 2026» → лента дней.
  static const double monthToDays = 21;

  /// Высота ленты дней: подпись дня + пилюля с числом, y 428…510.
  static const double daysHeight = 83;

  /// Колонка дня: подложка 40 в ширину при шаге 53.
  static const double dayColumnWidth = 40;
  static const double dayColumnPitch = 53;

  /// Пилюля с числом: 36×40, её верх на 37 от верха ленты (465 − 428).
  static const Size dayPillSize = Size(36, 40);
  static const double dayPillTop = 37;

  /// Лента дней → слоты времени.
  static const double daysToSlots = 18;

  /// Слот времени: высота 42, поля 13, зазор 12.
  static const double slotHeight = 42;
  static const double slotPaddingH = 13;
  static const double slotGap = 12;

  /// Слоты → кнопки.
  static const double slotsToActions = 11;

  /// Кнопки внутри карточки: y 580…640.
  static const double cardActionHeight = 61;

  /// В макете кнопки в карточке неравной ширины: 188 и 161.
  static const int cardActionLeftFlex = 188;
  static const int cardActionRightFlex = 161;

  /// Зазор между кнопками.
  static const double actionGap = 15;

  // ─── Экран «Ваша запись» ───────────────────────────────────────────────

  /// Карточка записи: y 334…402.
  static const double summaryHeight = 69;

  /// Шапка → карточка записи (305 → 334).
  static const double photoToSummary = 29;

  /// Карточка записи → кнопки звонка (402 → 413).
  static const double summaryToActions = 11;

  /// Кнопки звонка выше, чем внутри карточки: y 413…480.
  static const double callActionHeight = 67;

  /// Кнопки звонка → карточка «Перенести запись» (480 → 523).
  static const double actionsToReschedule = 43;

  // ─── Отзывы ────────────────────────────────────────────────────────────

  /// Карточка расписания → карточка отзывов (659 → 679).
  static const double cardGap = 20;

  /// Белая карточка отзыва внутри синей: x 33…407, y 722…877.
  static const double reviewInset = 13;
  static const double reviewPadding = 13;

  /// Заголовок «Топ отзывов» → карточка отзыва.
  static const double reviewsTitleToCard = 10;

  /// Точки карусели: полоса из трёх занимает x 204…236 при высоте 8.
  static const double dotSize = 7;
  static const double dotGap = 6;
  static const double reviewsToDots = 13;

  /// Поле «Оставьте свой отзыв»: y 913…963.
  static const double composerHeight = 50;
  static const double composerTop = 10;
}
