/// Врач в каталоге телемедицины.
class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.clinic,
    required this.rating,
    required this.experienceYears,
    this.city,
    this.photoUrl,
    this.reviewsCount = 0,
    this.price,
    this.priceBeforeDiscount,
  });

  final String id;
  final String fullName;
  final String specialty;

  /// Одной строкой, как на макете: «Название клиники, улица, город».
  final String clinic;

  /// Средняя оценка, 0…5. В чипе показывается с одним знаком: «4.5».
  final double rating;

  final int experienceYears;

  /// Город приёма — чип в правом углу шапки. На экране записи его нет.
  final String? city;

  /// Фотография-вырезка на подложке шапки. Приходит с бэкенда; пока пусто.
  final String? photoUrl;

  /// «100 отзывов» в результатах поиска. На экране профиля не показывается.
  final int reviewsCount;

  /// Цена консультации в тенге. `null` — цены нет (например, на экране
  /// профиля врача, вне поиска). Мок для теста вёрстки; настоящая цена и
  /// правило скидки для Gold — с бэкенда.
  final int? price;

  /// Цена до скидки — зачёркнута рядом с [price] на макете
  /// `design/Поиск врача результаты - Gold.png`. `null` — скидки нет.
  final int? priceBeforeDiscount;

  /// Текст чипа рейтинга: «4.5».
  String get ratingLabel => rating.toStringAsFixed(1);

  /// Текст чипа стажа: «Стаж 10 лет».
  ///
  /// Русские числительные: 1 год, 2–4 года, 5–20 лет, дальше по последней
  /// цифре.
  String get experienceLabel {
    final tail = experienceYears % 100;
    final last = experienceYears % 10;
    final String word;
    if (tail >= 11 && tail <= 14) {
      word = 'лет';
    } else if (last == 1) {
      word = 'год';
    } else if (last >= 2 && last <= 4) {
      word = 'года';
    } else {
      word = 'лет';
    }
    return 'Стаж $experienceYears $word';
  }

  /// «10 000 ₸» — разряды разделены пробелом, как на
  /// `design/Поиск врача результаты - Gold.png` (там разделитель — точка,
  /// но пробел — общий разделитель разрядов в остальном приложении).
  String? get priceLabel => _withThousands(price);

  /// Зачёркнутая цена до скидки, тем же форматом.
  String? get priceBeforeDiscountLabel => _withThousands(priceBeforeDiscount);

  static String? _withThousands(int? value) {
    if (value == null) return null;
    final digits = value.toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = end - 3 < 0 ? 0 : end - 3;
      groups.insert(0, digits.substring(start, end));
    }
    return groups.join(' ');
  }
}
