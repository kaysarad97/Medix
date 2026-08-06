import '../../../../core/utils/ru_plurals.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/subscription_tier.dart';

/// Владелец аккаунта — то, что видно в шапке экрана «Ваша Мед-Карта»
/// и правится в «Настройках профиля».
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthDate,
    required this.subscription,
    this.email,
    this.iin,
    this.registrationAddress,
    this.heightCm,
    this.weightKg,
    this.avatarUrl,
    this.avatarAsset,
  });

  final String id;
  final String firstName;
  final String lastName;
  final Gender gender;
  final DateTime birthDate;
  final SubscriptionTier subscription;

  final String? email;

  /// ИИН. Пустой, пока пользователь не заполнил мед-карту.
  final String? iin;

  final String? registrationAddress;
  final int? heightCm;
  final int? weightKg;

  /// Аватар с бэкенда. Пока пусто — аватарки лежат в сборке.
  final String? avatarUrl;

  /// Выбранная аватарка из набора в сборке — см. `MedixAvatars`.
  final String? avatarAsset;

  /// «Имя Фамилия» — в макете в две строки, перенос делает вёрстка.
  String get fullName => '$firstName $lastName';

  /// Дата рождения в шапке: «6/12/1996».
  ///
  /// Без ведущих нулей и через косую черту — так в макете, в отличие от
  /// «10.07» в записях к врачу.
  String get birthDateLabel =>
      '${birthDate.day}/${birthDate.month}/${birthDate.year}';

  /// Полных лет на сегодня. Плитка «Возраст» в карточке мед-карты.
  int ageAt(DateTime now) {
    var years = now.year - birthDate.year;
    final hadBirthday =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  /// «30 лет» — с русским числительным.
  String ageLabel(DateTime now) => RuPlurals.years(ageAt(now));

  /// «176 см», либо прочерк, пока рост не заполнен.
  String get heightLabel => heightCm == null ? '—' : '$heightCm см';

  /// «77 кг».
  String get weightLabel => weightKg == null ? '—' : '$weightKg кг';
}
