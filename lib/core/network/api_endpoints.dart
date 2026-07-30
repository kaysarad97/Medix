/// Пути API MedIx.
///
/// Бэкенд (FastAPI) в разработке — базовый адрес задаётся через
/// `--dart-define=MEDIX_API_URL=...`, значение по умолчанию временное.
abstract final class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'MEDIX_API_URL',
    defaultValue: 'https://api.medix.kz/v1',
  );

  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyCode = '/auth/verify';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String googleSignIn = '/auth/google';
}
