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
    required this.birthDate,
    required this.relation,
    this.gender,
    this.relationshipLabel,
    this.registrationAddress,
    this.heightCm,
    this.weightKg,
    this.avatarAsset,
  });

  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final FamilyRelation relation;

  /// Пол. Необязателен, потому что бэкенд его не хранит: у члена семьи есть
  /// только имя, дата рождения и родство. С сервера всегда приходит `null`,
  /// и в карточке на этом месте прочерк — спрашивать пол в форме, чтобы тут
  /// же его потерять, честнее не заводить вовсе. Поле останется, пока не
  /// ответит дизайнер, показывать ли его вообще.
  final Gender? gender;

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
  ///
  /// Через фильтр, а не склейкой: с бэкенда приходит одно поле `full_name`,
  /// и в нём может не оказаться фамилии — тогда склейка дала бы висящий
  /// пробел.
  String get fullName =>
      [firstName, lastName].where((part) => part.isNotEmpty).join(' ');

  /// Прочерк — тем же знаком, что у роста и веса, которых на сервере тоже
  /// нет: в карточке это одна строка сведений, и разнобой в ней заметен.
  String get genderLabel => gender?.label ?? '—';

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

  // Заголовки карточек «Врачи…»/«Анализы…» — в виджете, не здесь: у entity
  // нет доступа к BuildContext, нужного `AppLocalizations.of(context)`.
}
