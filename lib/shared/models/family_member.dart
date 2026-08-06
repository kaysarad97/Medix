import '../../core/utils/ru_plurals.dart';
import 'gender.dart';

/// Кто это по отношению к владельцу аккаунта. Определяет и обращение в
/// заголовках карточек («Врачи моего ребёнка» / «Врачи для старших»), и
/// аватар по умолчанию.
enum FamilyRelation { child, senior }

/// Член семьи в «Моя Семья» (`design/Моя Семья Ребенок.png`,
/// `design/Моя Семья Старшие.png`).
///
/// Нужен и фиче `family_access` (собственная карточка), и `profile`
/// (переключатель семьи на «Ваша Мед-Карта») — поэтому в `shared/`, а не в
/// одной из фич.
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    required this.relation,
    this.relationshipLabel,
    this.registrationAddress,
    this.heightCm,
    this.weightKg,
    this.avatarAsset,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final DateTime birthDate;
  final FamilyRelation relation;

  /// «Сын», «Дочь», «Мама» — поле «Родство с Вами» в мед-карте. В обоих
  /// макетах не заполнено, поэтому мок оставляет `null`, как и с
  /// [registrationAddress].
  final String? relationshipLabel;

  final String? registrationAddress;
  final int? heightCm;
  final int? weightKg;

  /// Выбранная аватарка из набора в сборке — см. `MedixAvatars`. Своих
  /// иллюстраций для детей/старших дизайнер не присылал, поэтому мок берёт
  /// подходящую по стилю из общего набора.
  final String? avatarAsset;

  /// «Имя Фамилия».
  String get fullName => '$firstName $lastName';

  /// «7/10/2020» — тот же формат, что в шапке профиля пользователя.
  String get birthDateLabel =>
      '${birthDate.day}/${birthDate.month}/${birthDate.year}';

  int ageAt(DateTime now) {
    var years = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  String ageLabel(DateTime now) => RuPlurals.years(ageAt(now));

  String get heightLabel => heightCm == null ? '—' : '$heightCm см';

  String get weightLabel => weightKg == null ? '—' : '$weightKg кг';

  /// Заголовок карточки «Врачи…» — по макету разный для ребёнка и старших.
  String get doctorsCardTitle => switch (relation) {
    FamilyRelation.child => 'Врачи моего ребёнка',
    FamilyRelation.senior => 'Врачи для старших',
  };

  /// Заголовок карточки анализов. У ребёнка — родовое «ребёнка», у старших
  /// — имя: так расходятся оба макета, а не по недосмотру.
  String get analysesCardTitle => switch (relation) {
    FamilyRelation.child => 'Анализы ребёнка',
    FamilyRelation.senior => 'Анализы $fullName',
  };
}
