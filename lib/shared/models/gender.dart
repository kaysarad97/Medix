/// Нужен и профилю пользователя, и карточкам членов семьи — поэтому в
/// `shared/`, а не в одной из фич.
enum Gender {
  male('мужчина'),
  female('женщина');

  const Gender(this.label);

  final String label;
}
