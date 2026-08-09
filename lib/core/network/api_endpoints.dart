/// Пути API MedIx.
///
/// Базовый адрес задаётся сборочным флагом:
/// `flutter run --dart-define=MEDIX_API_URL=http://192.168.1.65:8000`.
/// Значение по умолчанию рассчитано на бэкенд, поднятый на той же машине;
/// для эмулятора Android хост-машина видна как `10.0.2.2`, для реального
/// устройства нужен адрес машины в локальной сети.
///
/// Версионного префикса у бэкенда нет — пути идут от корня.
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'MEDIX_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Регистрация в два шага: заявка с данными профиля, затем код из письма.
  static const String registerStart = '/auth/register/start';
  static const String registerVerify = '/auth/register/verify';

  /// Вход тоже в два шага — пароля нет, сервер присылает одноразовый код.
  static const String loginStart = '/auth/login/start';
  static const String loginVerify = '/auth/login/verify';

  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';

  /// Профиль текущего пользователя.
  static const String me = '/users/me';

  /// Запросы к этой ветке уходят без токена доступа и не перезапрашиваются
  /// после 401: часть из них анонимна, а `/auth/refresh` и `/auth/logout`
  /// носят refresh-токен в теле. Единое правило избавляет от рекурсии в
  /// [AuthInterceptor].
  static const String authPrefix = '/auth/';
}
