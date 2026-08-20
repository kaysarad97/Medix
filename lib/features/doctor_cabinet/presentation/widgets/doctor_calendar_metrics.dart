/// Размеры календаря кабинета врача, снятые с
/// `design/.../Календарь.png` (440×956, один в один в обоих комплектах
/// макетов — экран общий для клиники и фрилансера).
abstract final class DoctorCalendarMetrics {
  static const double screenH = 21;
  static const double cardPadding = 13;

  /// Верх «Четверг» после топ-бара.
  static const double topBarToHeading = 30;

  /// «Четверг» → подпись «21-ое июля, 2026 год».
  static const double headingToSubtitle = 6;

  /// Подпись → карточка дней недели: 242.
  static const double subtitleToDayStrip = 30;

  /// Карточка дней недели: 242…366 — 124.
  static const double dayStripHeight = 124;

  /// Карточка дней недели → карточка записей: 366…397 — 31.
  static const double dayStripToBuckets = 31;

  /// Заголовок корзины («Утренние записи» и т.д.): 397…450 — 53.
  static const double bucketHeaderHeight = 53;

  /// Заголовок → первая строка записи внутри корзины.
  static const double bucketHeaderToRows = 12;

  /// Строка записи: 64, тот же порядок, что и на главной.
  static const double rowHeight = 64;
  static const double rowGap = 4;

  /// Между корзинами («Утренние записи» → «Дневные записи»).
  static const double bucketGap = 20;

  /// Ширина колонки дня в полосе: подогнана под 7 колонок в 440 с полями
  /// экрана, тем же приёмом, что у `DoctorMetrics.dayColumnWidth`.
  static const double dayColumnWidth = 40;
  static const double dayColumnGap = 13;
  static const double dayLabelHeight = 40;
  static const double dayPillSize = 40;
}
