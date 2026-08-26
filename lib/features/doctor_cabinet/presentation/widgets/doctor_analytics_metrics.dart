/// Размеры «Аналитики Работы», снятые с
/// `design/для врача от клиники/Аналитика Работы.png` (440×956).
abstract final class DoctorAnalyticsMetrics {
  static const double screenH = 21;
  static const double cardPadding = 13;

  /// Отступ до верхней строки — как на остальных экранах кабинета.
  static const double topBarTop = 30;

  /// Топ-бар кончается на 126, карточка недели начинается на 168.
  static const double topBarToCard = 42;

  /// Карточка недели: 168…515.
  static const double weekCardHeight = 348;

  /// Между карточками недели и месяца: 515…548.
  static const double cardGap = 33;

  /// Шапка карточки (заголовок с пейджером) до содержимого.
  static const double headerHeight = 44;

  /// Столбчатый график: сами столбики без подписей.
  static const double barChartHeight = 76;
  static const double barWidth = 24;

  /// Ломаная за месяц внутри белой карточки.
  static const double lineChartHeight = 96;

  /// Плитка показателя: «49 минут» и подпись-пилюля под ней.
  static const double statTileHeight = 90;
  static const double statTileGap = 9;
}
