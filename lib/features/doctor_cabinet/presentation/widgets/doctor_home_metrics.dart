/// Размеры главного экрана кабинета врача, снятые с
/// `design/для врача от клиники/Главная - в.ф.png` (440×1330).
abstract final class DoctorHomeMetrics {
  /// Все карточки по одной сетке с пациентской главной: x 21…419.
  static const double screenH = 21;

  static const double cardPadding = 13;

  /// Верх аватара при безопасной зоне — как на пациентской главной.
  static const double headerTop = 23;

  static const double avatarSize = 60;

  static const double headerToGreeting = 14;

  /// Приветствие → карточка плиток.
  static const double greetingToTiles = 34;

  /// Между карточками верхнего уровня: 472→497, 581→606, 837→кнопка,
  /// 1101→1126 — везде около 25.
  static const double cardGap = 25;

  /// Плитки «График работы» / «История записей»: 95 в высоту, снято по
  /// аналогии с пациентской `actionTileHeight` — сама карточка 263…472
  /// содержит и их, и широкую плитку ниже.
  static const double tileRowHeight = 95;
  static const double tileGap = 14;

  /// Между рядом плиток и широкой плиткой «Аналитика активности» внутри
  /// одной карточки.
  static const double tilesToWideTile = 17;

  /// Широкая плитка (и «Аналитика активности» внутри карточки плиток, и
  /// отдельные «Мои сообщения»/«Администрация»): 497…581, 1126…1210 — 84.
  static const double wideTileHeight = 84;

  /// Строка записи в «Предстоящие записи»: 675…740 — 65, тот же размер,
  /// что и на пациентской главной.
  static const double appointmentRowHeight = 65;
  static const double appointmentRowGap = 20;

  /// Заголовок карточки → первая строка записи.
  static const double appointmentsTitleToList = 12;

  /// Поле «Напишите Medi-bot...» — тот же размер, что у пациентского поля
  /// поиска симптомов.
  static const double mediBotFieldHeight = 54;

  /// Заголовок «Постоянные пациенты» → грид.
  static const double patientsTitleToGrid = 16;

  /// Чип пациента в гриде 2×2: 986…1027 — 41.
  static const double patientChipHeight = 41;
  static const double patientChipGap = 12;
  static const double patientRowGap = 16;
}
