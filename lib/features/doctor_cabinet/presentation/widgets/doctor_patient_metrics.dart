/// Размеры «Профиля пациента» и «Записи с пациентом», снятые с
/// `design/для врача от клиники/Профиль пациента.png` (440×1438, страница
/// прокручиваемая) и `.../Запись с пациентом.png` (440×978).
///
/// Шапка в обоих макетах одна и та же, и все замеры её части совпадают
/// до пикселя.
abstract final class DoctorPatientMetrics {
  static const double screenH = 21;
  static const double cardPadding = 13;

  /// Отступ до верхней строки — как на остальных экранах кабинета.
  static const double topBarTop = 30;

  /// Топ-бар кончается на 126, аватар начинается на 150.
  static const double topBarToHeader = 24;

  /// Аватар: 21…143 по горизонтали, 150…291 по вертикали.
  static const double avatarWidth = 123;
  static const double avatarHeight = 142;

  /// Аватар → колонка с именем: 143…180.
  static const double avatarToInfo = 37;

  /// Аватар с 150, а имя — с 194: колонка справа начинается ниже.
  static const double avatarToName = 39;

  /// Имя 194…212, значения меты 236…245, подписи 254…263.
  static const double nameToMeta = 16;
  static const double metaValueToLabel = 0;

  /// Шапка → первая карточка: низ аватара 291 → карточка 315 на «Профиле
  /// пациента».
  static const double headerToCard = 24;

  /// На «Записи с пациентом» зазор больше: там строка записи начинается на
  /// 334. Один и тот же аватар, разные отступы — так в макетах.
  static const double headerToSummaryRow = 43;

  /// Кнопки → блок заключения: 481…514.
  static const double actionsToConclusion = 33;

  /// «Подтвердите запись»: заголовок 334…351, строка с датой 371…420.
  static const double confirmTitleToDate = 20;

  /// Пилюля времени в строке даты: 82×50.
  static const double timePillWidth = 82;
  static const double timePillHeight = 50;

  /// Строка даты → белая строка «Сообщение»: 420…433.
  static const double dateToMessageRow = 13;

  /// Белая строка внутри карточки: 433…499.
  static const double rowHeight = 67;

  /// Карточка → блок заключения: 514…543 на «Профиле пациента».
  static const double cardGap = 29;

  /// «Запись с пациентом»: строка записи 334…402, кнопки 414…481.
  static const double summaryRowHeight = 69;
  static const double summaryToActions = 12;
  static const double actionHeight = 68;
}
