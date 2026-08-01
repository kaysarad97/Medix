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
}
