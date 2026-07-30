import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_session.dart';

abstract interface class AuthRepository {
  /// [identifier] — e-mail или ИИН.
  Future<AuthSession> login({
    required String identifier,
    required String password,
  });

  /// Создаёт профиль и запускает отправку СМС с кодом на [phone].
  Future<void> register({
    required String email,
    required String password,
    required String iin,
    required String fullName,
    required String phone,
  });

  /// Подтверждает номер кодом из СМС и открывает сессию.
  Future<AuthSession> verifyCode({required String phone, required String code});

  Future<void> logout();
}

/// Боевая реализация поверх FastAPI-бэкенда.
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._dio, this._storage);

  final Dio _dio;
  final SecureStorageService _storage;

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'identifier': identifier, 'password': password},
      );
      final session = AuthSession.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String iin,
    required String fullName,
    required String phone,
  }) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.register,
        data: {
          'email': email,
          'password': password,
          'iin': iin,
          'full_name': fullName,
          'phone': phone,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.verifyCode,
        data: {'phone': phone, 'code': code},
      );
      final session = AuthSession.fromJson(response.data!);
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      return session;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post<void>(ApiEndpoints.logout);
    } on DioException {
      // Разлогин локально имеет смысл даже при недоступном сервере.
    } finally {
      await _storage.clear();
    }
  }
}

/// Заглушка на время разработки бэкенда.
///
/// Негативные сценарии, чтобы их можно было прогонять руками:
/// пароль `wrongpass` при входе, почта `taken@medix.kz` при регистрации,
/// код `00000` при подтверждении.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  /// Код, который заглушка считает верным.
  static const String validCode = '12345';

  @override
  Future<AuthSession> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (password == 'wrongpass') {
      throw const ApiException(
        'Неверный e-mail/ИИН или пароль',
        statusCode: 401,
      );
    }

    return AuthSession(
      user: AppUser(
        id: 'mock-user-1',
        email: identifier.contains('@') ? identifier : 'user@medix.kz',
        iin: identifier.contains('@') ? null : identifier,
        fullName: 'Тестовый Пользователь',
      ),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String iin,
    required String fullName,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (email == 'taken@medix.kz') {
      throw const ApiException(
        'Профиль с такой почтой уже существует',
        statusCode: 409,
      );
    }
  }

  @override
  Future<AuthSession> verifyCode({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (code != validCode) {
      throw const ApiException('Неверный код подтверждения', statusCode: 400);
    }

    return const AuthSession(
      user: AppUser(
        id: 'mock-user-1',
        email: 'user@medix.kz',
        fullName: 'Тестовый Пользователь',
      ),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }

  @override
  Future<void> logout() async {}
}
