/// Пути навигации.
abstract final class Routes {
  static const String login = '/login';

  /// Шаг 1 мастера регистрации — почта и пароль.
  static const String register = '/register';

  /// Шаг 2 — ИИН, ФИО, телефон.
  static const String personalData = '/register/personal';

  /// Шаг 3 — код из СМС.
  static const String verifyCode = '/register/verify';

  /// Шаг 4 — язык интерфейса и согласие на рассылки.
  static const String appSettings = '/register/settings';

  /// Шаг 5 — политика конфиденциальности.
  static const String policy = '/register/policy';

  static const String home = '/';

  /// Профиль врача с записью на приём.
  static const String doctor = '/doctor/:id';

  /// Оформленная запись к врачу.
  static const String appointment = '/appointment/:id';

  /// Профиль пользователя — «Ваша Мед-Карта».
  static const String profile = '/profile';

  /// Форма мед-карты: группа крови, аллергии, операции.
  static const String medicalCardForm = '/profile/medical-card';

  /// Настройки приложения.
  static const String settings = '/profile/settings';

  /// Настройки профиля: имя, почта, пароль.
  static const String profileSettings = '/profile/settings/account';

  /// «Свяжитесь с нами».
  static const String contacts = '/profile/settings/contacts';

  static String doctorOf(String id) => '/doctor/$id';

  static String appointmentOf(String id) => '/appointment/$id';
}
