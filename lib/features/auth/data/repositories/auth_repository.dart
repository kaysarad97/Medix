import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_session.dart';

/// Вход и регистрация по одноразовому коду из письма.
///
/// Паролей нет: бэкенд их не хранит. И вход, и регистрация идут в два шага —
/// сначала сервер отправляет код на почту, потом код обменивается на сессию.
abstract interface class AuthRepository {
  /// Шаг 1 регистрации: заводит заявку и отправляет код на [email].
  ///
  /// Возвращает время жизни кода в секундах — по нему экран ввода заводит
  /// обратный отсчёт.
  Future<int> registerStart({
    required String email,
    required String fullName,
    required DateTime birthDate,
  });

  /// Шаг 2 регистрации: обменивает код на сессию.
  Future<AuthSession> registerVerify({
    required String email,
    required String code,
  });

  /// Шаг 1 входа: просит сервер отправить код на [email].
  ///
  /// Ответ одинаков и для существующей почты, и для незнакомой — так сервер
  /// не даёт подбирать зарегистрированные адреса. Значит, «письмо ушло» на
  /// экране показываем всегда.
  Future<void> loginStart({required String email});

  /// Шаг 2 входа: обменивает код на сессию.
  Future<AuthSession> loginVerify({
    required String email,
    required String code,
  });

  Future<void> logout();
}

/// Дата в формате, который ждёт бэкенд: `1995-06-15`.
String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Боевая реализация поверх FastAPI-бэкенда.
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  @override
  Future<int> registerStart({
    required String email,
    required String fullName,
    required DateTime birthDate,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.registerStart,
        data: {
          'email': email,
          'full_name': fullName,
          'birth_date': _formatDate(birthDate),
        },
      );
      final expiresIn = response.data?['expires_in'];
      return expiresIn is int ? expiresIn : 0;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AuthSession> registerVerify({
    required String email,
    required String code,
  }) {
    return _verify(ApiEndpoints.registerVerify, email: email, code: code);
  }

  @override
  Future<void> loginStart({required String email}) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.loginStart,
        data: {'identifier': email},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AuthSession> loginVerify({
    required String email,
    required String code,
  }) {
    return _verify(ApiEndpoints.loginVerify, email: email, code: code);
  }

  /// Оба подтверждения устроены одинаково: `identifier` + `code` в обмен на
  /// пару токенов и профиль.
  Future<AuthSession> _verify(
    String path, {
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'identifier': email, 'code': code},
      );
      final session = AuthSession.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _storage.saveUserRole(session.user.role.name);
      return session;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post<void>(
          ApiEndpoints.logout,
          data: {'refresh_token': refreshToken},
        );
      }
    } on DioException {
      // Разлогин локально имеет смысл даже при недоступном сервере.
    } finally {
      await _storage.clear();
    }
  }
}

/// Заглушка для работы без бэкенда.
///
/// Негативные сценарии, чтобы их можно было прогонять руками:
/// почта `taken@medix.kz` при регистрации, код `000000` при подтверждении.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  /// Код, который заглушка считает верным. Длина — как у настоящего.
  static const String validCode = '123456';

  /// Столько же, сколько отдаёт бэкенд.
  static const int codeTtlSeconds = 300;

  @override
  Future<int> registerStart({
    required String email,
    required String fullName,
    required DateTime birthDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (email == 'taken@medix.kz') {
      throw const ApiException(
        'Данный email уже зарегистрирован, войдите',
        statusCode: 409,
      );
    }
    return codeTtlSeconds;
  }

  @override
  Future<AuthSession> registerVerify({
    required String email,
    required String code,
  }) => _verify(email: email, code: code);

  @override
  Future<void> loginStart({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Future<AuthSession> loginVerify({
    required String email,
    required String code,
  }) => _verify(email: email, code: code);

  Future<AuthSession> _verify({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (code != validCode) {
      throw const ApiException(
        'Неверный код, осталось попыток: 4',
        statusCode: 400,
      );
    }

    return AuthSession(
      user: AppUser(
        id: 'mock-user-1',
        email: email,
        fullName: 'Тестовый Пользователь',
      ),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<void> logout() async {}
}
