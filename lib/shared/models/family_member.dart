import '../../core/utils/ru_plurals.dart';
import 'gender.dart';

/// Кем член семьи приходится владельцу аккаунта.
///
/// Значения — перечисление бэкенда (`FamilyRelation` в OpenAPI). До
/// 17 августа 2026 сервер хранил здесь свободный текст, и приложение
/// угадывало группу по словам («сын», «мама») и по возрасту; теперь угадывать
/// нечего.
///
/// Макетов на пять степеней родства нет — их два, детский и взрослый,
/// поэтому подписи карточек и аватар по умолчанию различают только [isChild].
enum FamilyRelation {
  spouse('spouse'),
  child('child'),
  parent('parent'),
  sibling('sibling'),
  other('other');

  const FamilyRelation(this.api);

  /// Значение, которым родство ходит по API.
  final String api;

  /// Незнакомое значение — [other], а не исключение: сервер может завести
  /// новую степень родства раньше, чем приложение о ней узнает, и падать
  /// из-за этого весь список семьи не должен.
  static FamilyRelation fromApi(String? value) =>
      values.firstWhere((r) => r.api == value, orElse: () => other);

  bool get isChild => this == FamilyRelation.child;
}

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

  /// Пол. С 17 августа 2026 сервер его хранит (`sex` в `FamilyMemberOut`),
  /// но необязательным — у заведённых раньше членов семьи его нет, и в
  /// карточке на этом месте по-прежнему прочерк.
  final Gender? gender;

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
