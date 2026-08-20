/// Отзыв пациента о враче — на экране «Отзывы о Вас» в кабинете врача.
///
/// Не переиспользует `DoctorReview` из телемедицины: та сущность нужна
/// пациентскому экрану профиля врача, лежит в чужой фиче. Форма
/// совпадает случайно — отзыв касается и того, и другого экрана, но с
/// разных сторон.
class DoctorOwnReview {
  const DoctorOwnReview({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
  });

  final String id;
  final String authorName;
  final double rating;
  final String text;
}
