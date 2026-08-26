import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_session.dart';

abstract interface class DoctorRegistrationRepository {
  Future<int> start({
    required String email,
    required String fullName,
    required DateTime birthDate,
    required String specialty,
    required String licenseNumber,
    String? city,
  });

  Future<AuthSession> verify({required String email, required String code});
}

class RemoteDoctorRegistrationRepository
    implements DoctorRegistrationRepository {
  const RemoteDoctorRegistrationRepository(this._dio, this._storage);

  final Dio _dio;
  final AuthSessionStorage _storage;

  @override
  Future<int> start({
    required String email,
    required String fullName,
    required DateTime birthDate,
    required String specialty,
    required String licenseNumber,
    String? city,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.doctorRegisterStart,
        data: {
          'email': email,
          'full_name': fullName,
          'birth_date': _formatDate(birthDate),
          'specialty': specialty,
          'license_number': licenseNumber,
          if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        },
      );
      return response.data?['expires_in'] as int? ?? 0;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<AuthSession> verify({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.doctorRegisterVerify,
        data: {'identifier': email, 'code': code},
      );
      final session = AuthSession.fromJson(response.data!);
      if (session.user.role != AppUserRole.doctor) {
        throw const ApiException('Сервер вернул сессию без роли врача');
      }
      await _storage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      await _storage.saveUserRole(session.user.role.name);
      return session;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$month-$day';
  }
}

class MockDoctorRegistrationRepository implements DoctorRegistrationRepository {
  const MockDoctorRegistrationRepository();

  @override
  Future<int> start({
    required String email,
    required String fullName,
    required DateTime birthDate,
    required String specialty,
    required String licenseNumber,
    String? city,
  }) async => 300;

  @override
  Future<AuthSession> verify({
    required String email,
    required String code,
  }) async => AuthSession(
    user: AppUser(
      id: 'mock-doctor-1',
      email: email,
      role: AppUserRole.doctor,
      fullName: 'Тестовый Врач',
    ),
    accessToken: 'mock-doctor-access-token',
    refreshToken: 'mock-doctor-refresh-token',
  );
}
