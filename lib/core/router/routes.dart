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
}
