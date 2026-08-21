import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import 'auth_providers.dart';

enum DoctorRegField {
  email,
  fullName,
  birthDate,
  specialty,
  licenseNumber,
  city,
  code,
}

@immutable
class DoctorRegistrationState {
  const DoctorRegistrationState({
    this.values = const {},
    this.errors = const {},
    this.isSubmitting = false,
    this.formError,
    this.codeTtlSeconds = 0,
  });

  final Map<DoctorRegField, String> values;
  final Map<DoctorRegField, String> errors;
  final bool isSubmitting;
  final String? formError;
  final int codeTtlSeconds;

  String value(DoctorRegField field) => values[field] ?? '';
  String? errorOf(DoctorRegField field) => errors[field];

  DoctorRegistrationState copyWith({
    Map<DoctorRegField, String>? values,
    Map<DoctorRegField, String>? errors,
    bool? isSubmitting,
    String? formError,
    int? codeTtlSeconds,
  }) => DoctorRegistrationState(
    values: values ?? this.values,
    errors: errors ?? const {},
    isSubmitting: isSubmitting ?? this.isSubmitting,
    formError: formError,
    codeTtlSeconds: codeTtlSeconds ?? this.codeTtlSeconds,
  );
}

class DoctorRegistrationController extends Notifier<DoctorRegistrationState> {
  @override
  DoctorRegistrationState build() => const DoctorRegistrationState();

  void setField(DoctorRegField field, String value) {
    state = state.copyWith(
      values: {...state.values, field: value},
      errors: {...state.errors}..remove(field),
    );
  }

  Future<bool> start() async {
    if (state.isSubmitting) return false;
    final errors = <DoctorRegField, String>{};
    void validate(DoctorRegField field, String? error) {
      if (error != null) errors[field] = error;
    }

    validate(
      DoctorRegField.email,
      Validators.email(state.value(DoctorRegField.email)),
    );
    validate(
      DoctorRegField.fullName,
      Validators.fullName(state.value(DoctorRegField.fullName)),
    );
    validate(
      DoctorRegField.birthDate,
      Validators.birthDate(state.value(DoctorRegField.birthDate)),
    );
    for (final field in [
      DoctorRegField.specialty,
      DoctorRegField.licenseNumber,
    ]) {
      if (state.value(field).trim().isEmpty) {
        errors[field] = 'Обязательное поле';
      }
    }
    if (errors.isNotEmpty) {
      state = state.copyWith(errors: errors);
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final ttl = await ref
          .read(doctorRegistrationRepositoryProvider)
          .start(
            email: state.value(DoctorRegField.email).trim(),
            fullName: state.value(DoctorRegField.fullName).trim(),
            birthDate: DateTime.parse(state.value(DoctorRegField.birthDate)),
            specialty: state.value(DoctorRegField.specialty).trim(),
            licenseNumber: state.value(DoctorRegField.licenseNumber).trim(),
            city: state.value(DoctorRegField.city),
          );
      state = state.copyWith(isSubmitting: false, codeTtlSeconds: ttl);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSubmitting: false, formError: error.message);
      return false;
    }
  }

  Future<bool> resendCode() => start();

  Future<bool> verify() async {
    if (state.isSubmitting) return false;
    final error = Validators.otpCode(state.value(DoctorRegField.code));
    if (error != null) {
      state = state.copyWith(errors: {DoctorRegField.code: error});
      return false;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(doctorRegistrationRepositoryProvider)
          .verify(
            email: state.value(DoctorRegField.email).trim(),
            code: state.value(DoctorRegField.code),
          );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isSubmitting: false, formError: error.message);
      return false;
    }
  }

  void formErrorShown() => state = state.copyWith(values: state.values);
}

final doctorRegistrationControllerProvider =
    NotifierProvider<DoctorRegistrationController, DoctorRegistrationState>(
      DoctorRegistrationController.new,
    );
