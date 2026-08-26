/// Размеры экранов заявки в администрацию, снятые с
/// `design/для врача от клиники/Запросы к админу.png`,
/// `.../Запросы к админу (1).png`, `.../Набор текста запроса.png`,
/// `.../Мои заявки.png` и `.../Ответ от админа.png` (все 440×956).
abstract final class DoctorAdminMetrics {
  static const double screenH = 21;
  static const double cardPadding = 13;

  static const double topBarTop = 30;

  /// Заголовок «Заявка в администрацию» в макете занимает две строки:
  /// 105…145. Обычные 34 под него не подходят.
  static const double topBarHeight = 62;

  /// «Заявка в» и «администрацию» — 73 и 146 краски; чтобы строка
  /// переносилась там же, где в макете, ширина заголовка ограничена.
  static const double titleMaxWidth = 200;

  /// Топ-бар → подпись «Часто задаваемые вопросы:» и «Тема заявки:»:
  /// краска подписи в макете начинается на 185.
  static const double topBarToHeading = 21;

  /// Подпись → первый чип: 200…216.
  static const double headingToChips = 16;

  /// Чип темы: высота 47, между чипами 9. Ширина по тексту.
  static const double chipHeight = 47;
  static const double chipGap = 9;

  /// Поля пилюли по 14: краска «Нужно перенести запись» занимает 146 при
  /// ширине чипа 174.
  static const double chipPaddingH = 14;

  /// Выбранная тема → карточка текста: 259…275.
  static const double chipToCard = 16;

  /// Карточка текста заявки: 275…448.
  static const double composeCardHeight = 174;

  /// Карточка → строка вложения: 448…484.
  static const double cardToAttach = 36;

  /// Строка «Приложить файл»: 484…547.
  static const double attachRowHeight = 64;

  /// Кнопка «Отправить заявку» и «Создать новую заявку»: 780…832.
  static const double buttonHeight = 52;

  /// «Мои заявки»: карточка 176…298, между карточками 15.
  static const double requestCardHeight = 123;
  static const double requestCardGap = 15;

  /// Белая врезка с текстом внутри карточки: 230…283.
  static const double requestPreviewHeight = 54;

  /// «Ответ от админа»: карточка запроса 275…448, подпись ответа и
  /// карточка ответа под ней.
  static const double answerHeadingTop = 26;
}
