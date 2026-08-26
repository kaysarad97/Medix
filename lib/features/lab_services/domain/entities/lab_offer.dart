/// Предложение лаборатории на ту же корзину — строка экрана
/// «Партнерские лаборатории» (`design/Сравнение корзины.png`).
///
/// Цена здесь не сумма позиций, а расчёт лаборатории на идентичный набор:
/// у каждой свой прайс, поэтому итог отличается от нашего.
class LabOffer {
  const LabOffer({
    required this.id,
    required this.labName,
    required this.address,
    required this.rating,
    required this.isOpen,
    required this.distanceMeters,
    required this.price,
    this.logoAsset,
  });

  final String id;

  /// «Лаборатория N1», «КДЛ “Анализы”».
  final String labName;

  /// «Название лаборатории, улица, город».
  final String address;

  final double rating;

  /// Работает ли сейчас — «Открыто» или «Закрыто» в макете.
  final bool isOpen;

  final int distanceMeters;

  /// Цена за тот же набор анализов, в тенге.
  final int price;

  /// Логотип лаборатории. Дизайнер отдал заглушку «ЛОГО», настоящих нет —
  /// придут с бэкендом вместе со списком партнёров.
  final String? logoAsset;

  /// «4.5» — как в карточке врача, один знак после запятой.
  String get ratingLabel => rating.toStringAsFixed(1);

  /// «900м» — в макете без пробела.
  String get distanceLabel =>
      '$distanceMeters'
      'м';

  /// «2900 ₸».
  String get priceLabel => '$price ₸';
}
