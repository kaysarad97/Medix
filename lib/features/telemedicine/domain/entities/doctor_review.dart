import '../../../../core/utils/ru_dates.dart';

/// Отзыв о враче в карусели «Топ отзывов».
class DoctorReview {
  const DoctorReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorName;

  /// Оценка 0…5. На макете 4.5 — половина звезды закрашена.
  final double rating;

  final String text;

  /// Когда отзыв написан. Показывается только под своим отзывом на
  /// `design/Оставьте отзыв.png`; в карусели дат нет, и у чужих отзывов
  /// поле пустое — заглушка их не проставляет, а бэкенд отзывов не отдаёт
  /// вовсе.
  final DateTime? createdAt;

  /// «от 10.08.26».
  String? get dateLabel =>
      createdAt == null ? null : RuDates.dayMonthShortYear(createdAt!);
}
