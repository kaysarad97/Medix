/// Размеры «Истории записей» и «О прошлой записи», снятые с
/// `design/для врача от клиники/История записей.png` и
/// `.../О прошлой записи.png` (обе 440×956).
abstract final class DoctorHistoryMetrics {
  static const double screenH = 21;
  static const double cardPadding = 12;

  /// Отступ до верхней строки — тот же, что в календаре.
  static const double topBarTop = 30;

  /// Топ-бар кончается на 126, карточка месяца начинается на 166.
  static const double topBarToCard = 40;

  /// Карточка месяца: 166…342.
  static const double monthCardHeight = 177;

  /// Карточка месяца → поиск: 342…362.
  static const double monthCardToSearch = 20;

  /// Поле поиска: 362…403.
  static const double searchHeight = 42;

  /// Поиск → карточка «Предыдущая запись»: 403…423.
  static const double searchToPrevious = 20;

  /// Шапка карточки до первой строки: «Предыдущая запись» 423…468.
  static const double cardHeaderHeight = 45;

  /// Синяя карточка кончается на 549, серая начинается на 555.
  static const double previousToOthers = 6;

  /// Шапка «Другие записи» с пейджером: 555…616.
  static const double othersHeaderHeight = 61;

  /// Строка записи: 616…684.
  static const double rowHeight = 69;
  static const double rowGap = 7;

  /// Кружок вида записи в строке: 45…76 по горизонтали, 32×32.
  static const double rowIconSize = 32;
  static const double rowIconGap = 12;

  /// «О прошлой записи»: карточка вида записи 166…260.
  static const double pastSummaryHeight = 95;

  /// Карточка вида записи → строка пациента: 260…277.
  static const double summaryToPatientRow = 17;

  /// Строка пациента: 277…343.
  static const double patientRowHeight = 67;

  /// Строка пациента → блок заключения: 343…366.
  static const double patientRowToConclusion = 23;

  /// Шапка блока заключения до белой карточки с текстом: 366…408.
  static const double conclusionHeaderHeight = 42;

  /// Белая карточка с текстом заключения: 408…510.
  static const double conclusionBodyHeight = 103;

  /// Текст → кнопка «Загрузить заключение»: 510…526.
  static const double conclusionBodyToUpload = 16;

  /// Кнопка «Загрузить заключение»: 526…571.
  static const double uploadRowHeight = 46;
}
