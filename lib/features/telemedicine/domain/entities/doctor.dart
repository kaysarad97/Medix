import '../../../../core/utils/ru_money.dart';

/// Врач в каталоге телемедицины.
class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    required this.specialty,
    required this.rating,
    this.clinic,
    this.experienceYears,
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
  ///
  /// Пусто — строка не рисуется. С бэкенда приходит только `clinic_id`, а
  /// эндпоинта клиник для пациента нет, так что развернуть его в название
  /// пока нечем (вопрос задан).
  final String? clinic;

  /// Средняя оценка, 0…5. В чипе показывается с одним знаком: «4.5».
  final double rating;

  /// Стаж в годах. Пусто — чип не рисуется: бэкенд стаж не хранит.
  final int? experienceYears;

  /// Город приёма — чип в правом углу шапки. На экране записи его нет.
  final String? city;

  /// Фотография-вырезка на подложке шапки. Приходит с бэкенда; пока пусто.
  final String? photoUrl;

  /// «100 отзывов» в результатах поиска. На экране профиля не показывается.
  final int reviewsCount;

  /// Цена консультации в тенге. `null` — цены нет (например, на экране
  /// профиля врача, вне поиска). Мок для теста вёрстки; настоящая цена и
  /// правило скидки для подписчика — с бэкенда.
  final int? price;

  /// Цена до скидки — зачёркнута рядом с [price] на макете
  /// `design/Поиск врача результаты - Gold.png`. `null` — скидки нет.
  final int? priceBeforeDiscount;

  /// Текст чипа рейтинга: «4.5».
  String get ratingLabel => rating.toStringAsFixed(1);

  /// Текст чипа стажа: «Стаж 10 лет». `null` — стажа не знаем.
  ///
  /// Русские числительные: 1 год, 2–4 года, 5–20 лет, дальше по последней
  /// цифре.
  String? get experienceLabel {
    final years = experienceYears;
    if (years == null) return null;

    final tail = years % 100;
    final last = years % 10;
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
    return 'Стаж $years $word';
  }

  /// «10 000 ₸» — разряды разделены пробелом, как на
  /// `design/Поиск врача результаты - Gold.png` (там разделитель — точка,
  /// но пробел — общий разделитель разрядов в остальном приложении).
  String? get priceLabel => RuMoney.withThousands(price);

  /// Зачёркнутая цена до скидки, тем же форматом.
  String? get priceBeforeDiscountLabel =>
      RuMoney.withThousands(priceBeforeDiscount);
}
