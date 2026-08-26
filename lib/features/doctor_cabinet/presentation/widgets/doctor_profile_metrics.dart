/// Размеры «Ваш Профиль», снятые с
/// `design/для врача от клиники/Профиль -  в.ф.png` (440 в ширину — сама
/// страница прокручиваемая, макет экспортирован коллажем с шапкой
/// таб-бара поверх содержимого; читать по секциям, а не по общей высоте).
abstract final class DoctorProfileMetrics {
  static const double screenH = 21;
  static const double cardPadding = 13;

  static const double topBarToPhoto = 20;

  /// Фото врача — тот же порядок величины, что у пациентской
  /// `DoctorMetrics.photoSize` в телемедицине.
  static const double photoWidth = 120;
  static const double photoHeight = 125;
  static const double photoToInfo = 16;

  static const double nameToMeta = 10;
  static const double metaGap = 24;

  static const double photoToCard = 24;

  /// Поле «Специализация»/«Опыт работы»/... — тот же размер, что у
  /// текстовых полей в формах (карта оплаты, регистрация).
  static const double fieldHeight = 52;
  static const double fieldGap = 12;
  static const double headerToFields = 20;
  static const double fieldsToToggle = 16;
  static const double toggleHeight = 52;

  static const double cardGap = 25;

  /// Строка-ссылка («Ваши сертификаты» и т.д.) — тот же размер, что у
  /// пациентских настроек (`ProfileMetrics.settingsRowHeight`).
  static const double linkRowHeight = 74;
  static const double linkRowGap = 12;
}
