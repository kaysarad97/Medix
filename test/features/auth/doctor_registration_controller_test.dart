import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/auth/data/models/auth_session.dart';
import 'package:medix/features/auth/data/repositories/doctor_registration_repository.dart';
import 'package:medix/features/auth/domain/entities/app_user.dart';
import 'package:medix/features/auth/presentation/providers/auth_providers.dart';
import 'package:medix/features/auth/presentation/providers/doctor_registration_controller.dart';

void main() {
  test('валидные данные запускают регистрацию врача', () async {
    final repository = _FakeDoctorRegistrationRepository();
    final container = ProviderContainer(
      overrides: [
        doctorRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      doctorRegistrationControllerProvider.notifier,
    );
    _fill(controller);

    expect(await controller.start(), isTrue);
    expect(repository.email, 'doctor@medix.kz');
    expect(repository.specialty, 'Кардиолог');
    expect(
      container.read(doctorRegistrationControllerProvider).codeTtlSeconds,
      300,
    );
  });

  test('обязательные поля проверяются до repository', () async {
    final repository = _FakeDoctorRegistrationRepository();
    final container = ProviderContainer(
      overrides: [
        doctorRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final ok = await container
        .read(doctorRegistrationControllerProvider.notifier)
        .start();

    expect(ok, isFalse);
    expect(repository.email, isNull);
    expect(
      container
          .read(doctorRegistrationControllerProvider)
          .errorOf(DoctorRegField.specialty),
      isNotNull,
    );
  });

  test('код подтверждает врачебную сессию', () async {
    final repository = _FakeDoctorRegistrationRepository();
    final container = ProviderContainer(
      overrides: [
        doctorRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(
      doctorRegistrationControllerProvider.notifier,
    );
    _fill(controller);
    controller.setField(DoctorRegField.code, '123456');

    expect(await controller.verify(), isTrue);
    expect(repository.code, '123456');
  });
}

void _fill(DoctorRegistrationController controller) {
  controller
    ..setField(DoctorRegField.email, 'doctor@medix.kz')
    ..setField(DoctorRegField.fullName, 'Доктор Тест')
    ..setField(DoctorRegField.birthDate, '1985-01-02')
    ..setField(DoctorRegField.specialty, 'Кардиолог')
    ..setField(DoctorRegField.licenseNumber, 'LIC-123')
    ..setField(DoctorRegField.city, 'Алматы');
}

class _FakeDoctorRegistrationRepository
    implements DoctorRegistrationRepository {
  String? email;
  String? specialty;
  String? code;

  @override
  Future<int> start({
    required String email,
    required String fullName,
    required DateTime birthDate,
    required String specialty,
    required String licenseNumber,
    String? city,
  }) async {
    this.email = email;
    this.specialty = specialty;
    return 300;
  }

  @override
  Future<AuthSession> verify({
    required String email,
    required String code,
  }) async {
    this.code = code;
    return AuthSession(
      user: AppUser(id: 'd1', email: email, role: AppUserRole.doctor),
      accessToken: 'access',
      refreshToken: 'refresh',
    );
  }
}
