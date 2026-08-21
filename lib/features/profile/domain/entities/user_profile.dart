import '../../../../core/utils/ru_plurals.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/subscription_tier.dart';

class AvatarUploadTicket {
  const AvatarUploadTicket({
    required this.uploadUrl,
    required this.fields,
    required this.key,
    required this.expiresAt,
  });

  final String uploadUrl;
  final Map<String, String> fields;
  final String key;
  final DateTime expiresAt;
}

/// Владелец аккаунта — то, что видно в шапке экрана «Ваша Мед-Карта»
/// и правится в «Настройках профиля».
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.subscription,
    this.gender,
    this.birthDate,
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

  /// Пол. С 17 августа 2026 сервер его хранит (`sex`), но необязательным —
  /// у заведённых раньше аккаунтов его нет, и в шапке остаётся прочерк.
  final Gender? gender;

  /// Дата рождения. Приходит с `GET /users/me` — до 17 августа 2026 сервер
  /// её принимал, но не возвращал, и в шапке стоял прочерк.
  final DateTime? birthDate;
  final SubscriptionTier subscription;

  /// Почта — она же логин: вход идёт по коду, присланному на неё.
  final String? email;

  /// ИИН — верхнее поле карточки «Мед-карта» в макете. С 17 августа 2026
  /// сервер снова его хранит, но заполнить может только правка профиля:
  /// регистрация ИИН не принимает.
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

  /// Пол в шапке, либо прочерк — тем же знаком, что у роста и веса.
  String get genderLabel => gender?.label ?? '—';

  /// Дата рождения в шапке: «6/12/1996».
  ///
  /// Без ведущих нулей и через косую черту — так в макете, в отличие от
  /// «10.07» в записях к врачу.
  String get birthDateLabel {
    final date = birthDate;
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Полных лет на сегодня. Плитка «Возраст» в карточке мед-карты.
  /// `null` — даты рождения не знаем.
  int? ageAt(DateTime now) {
    final date = birthDate;
    if (date == null) return null;

    var years = now.year - date.year;
    final hadBirthday =
        now.month > date.month ||
        (now.month == date.month && now.day >= date.day);
    if (!hadBirthday) years -= 1;
    return years;
  }

  /// «30 лет» — с русским числительным, либо прочерк.
  String ageLabel(DateTime now) {
    final years = ageAt(now);
    return years == null ? '—' : RuPlurals.years(years);
  }

  /// «176 см», либо прочерк, пока рост не заполнен.
  String get heightLabel => heightCm == null ? '—' : '$heightCm см';

  /// «77 кг».
  String get weightLabel => weightKg == null ? '—' : '$weightKg кг';
}
