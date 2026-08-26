/// Размеры формы мед-карты, снятые с `design/Медкарта.png` (440×956).
///
/// Карточка тянется ниже экрана — страница прокручиваемая.
abstract final class MedicalCardMetrics {
  /// Карточка формы: x 21…418, начинается на y 146.
  static const double cardTop = 146;
  static const double cardPadding = 13;

  /// Подпись → элемент под ней (краска подписи 179 → бокс 194).
  static const double labelToControl = 15;

  /// Элемент → следующая подпись (бокс 259 → краска 281).
  static const double controlToLabel = 21;

  /// Боксы группы крови: четыре по 62 с шагом 74, полоса 75…364.
  static const double bloodBoxWidth = 62;
  static const double bloodBoxHeight = 66;
  static const double bloodBoxGap = 12;

  /// Кнопки «Rh+ / Rh−» занимают всю ширину карточки: 34…405.
  static const double rhesusHeight = 46;

  /// Кнопки «Да / Нет» уже: 159 каждая, полоса 34…363.
  static const double yesNoWidth = 159;
  static const double yesNoHeight = 48;
  static const double yesNoGap = 13;

  /// Текстовое поле: 330 в ширину, 38 в высоту.
  static const double fieldWidth = 330;
  static const double fieldHeight = 38;

  /// Поля роста и веса: пара по 159, высота 50.
  static const double numberFieldHeight = 50;

  /// Кнопка сохранения под формой.
  static const double saveButtonTop = 28;
}
