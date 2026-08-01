/// Отзыв о враче в карусели «Топ отзывов».
class DoctorReview {
  const DoctorReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
  });

  final String id;
  final String authorName;

  /// Оценка 0…5. На макете 4.5 — половина звезды закрашена.
  final double rating;

  final String text;
}
