import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/network/api_exception.dart';
import 'package:medix/features/auth/data/repositories/doctor_registration_repository.dart';
import 'package:medix/features/auth/domain/entities/app_user.dart';
import 'package:medix/shared/services/secure_storage_service.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('отправляет все поля врача и возвращает TTL кода', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /auth/doctor/register/start': (
        statusCode: 201,
        body: {'expires_in': 300},
      ),
    });

    final ttl =
        await RemoteDoctorRegistrationRepository(
          dio,
          _RecordingSessionStorage(),
        ).start(
          email: 'doctor@medix.kz',
          fullName: 'Доктор Тест',
          birthDate: DateTime(1985, 1, 2),
          specialty: 'Кардиолог',
          licenseNumber: 'LIC-123',
          city: ' Алматы ',
        );

    expect(ttl, 300);
    expect(adapter.requests.single.data, {
      'email': 'doctor@medix.kz',
      'full_name': 'Доктор Тест',
      'birth_date': '1985-01-02',
      'specialty': 'Кардиолог',
      'license_number': 'LIC-123',
      'city': 'Алматы',
    });
  });

  test('подтверждает код и сохраняет врачебную сессию', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /auth/doctor/register/verify': (
        statusCode: 200,
        body: {
          'access_token': 'access',
          'refresh_token': 'refresh',
          'token_type': 'bearer',
          'is_new_user': true,
          'user': {
            'id': 'u1',
            'email': 'doctor@medix.kz',
            'role': 'doctor',
            'full_name': 'Доктор Тест',
            'phone': null,
          },
        },
      ),
    });
    final storage = _RecordingSessionStorage();

    final session = await RemoteDoctorRegistrationRepository(
      dio,
      storage,
    ).verify(email: 'doctor@medix.kz', code: '123456');

    expect(session.user.role, AppUserRole.doctor);
    expect(adapter.requests.single.data, {
      'identifier': 'doctor@medix.kz',
      'code': '123456',
    });
    expect(storage.accessToken, 'access');
    expect(storage.refreshToken, 'refresh');
    expect(storage.role, 'doctor');
  });

  test('не сохраняет сессию с неверной ролью', () async {
    final (:dio, adapter: _) = cannedDio({
      'POST /auth/doctor/register/verify': (
        statusCode: 200,
        body: {
          'access_token': 'access',
          'refresh_token': 'refresh',
          'user': {'id': 'u1', 'email': 'patient@medix.kz', 'role': 'patient'},
        },
      ),
    });
    final storage = _RecordingSessionStorage();

    await expectLater(
      RemoteDoctorRegistrationRepository(
        dio,
        storage,
      ).verify(email: 'patient@medix.kz', code: '123456'),
      throwsA(isA<ApiException>()),
    );
    expect(storage.accessToken, isNull);
    expect(storage.role, isNull);
  });
}

class _RecordingSessionStorage implements AuthSessionStorage {
  String? accessToken;
  String? refreshToken;
  String? role;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> saveUserRole(String role) async => this.role = role;
}
