import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/data/models/auth_session.dart';
import 'package:medix/features/auth/domain/entities/app_user.dart';

void main() {
  test('роль врача читается из ответа подтверждения кода', () {
    final session = AuthSession.fromJson({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user': {
        'id': 'u1',
        'email': 'doctor@medix.kz',
        'full_name': 'Доктор Тестовый',
        'role': 'doctor',
      },
    });

    expect(session.user.role, AppUserRole.doctor);
  });

  test('старый ответ без роли остаётся пациентским', () {
    final session = AuthSession.fromJson({
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user': {'id': 'u1', 'email': 'patient@medix.kz'},
    });

    expect(session.user.role, AppUserRole.patient);
  });
}
