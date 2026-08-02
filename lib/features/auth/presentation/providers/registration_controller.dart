import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/app_language.dart';
import 'auth_providers.dart';

/// Текстовые поля мастера регистрации.
enum RegField { email, password, passwordConfirm, iin, fullName, phone, code }

@immutable
class RegistrationState {
  const RegistrationState({
    this.values = const {},
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.formError,
    this.language,
    this.pushConsent = false,
    this.policyAccepted = false,
  });

  final Map<RegField, String> values;
  final Map<RegField, String> fieldErrors;
  final bool isSubmitting;

  /// Ошибка, не привязанная к полю (отказ сервера, нет сети).
  final String? formError;

  /// Выбранный язык интерфейса. `null` — пользователь ещё не выбрал;
  /// умолчания нет намеренно, шаг требует явного выбора.
  final AppLanguage? language;

  /// Согласие на push, СМС и письма. Необязательное: согласие на рекламные
  /// рассылки нельзя делать условием регистрации.
  final bool pushConsent;

  /// Согласие с политикой конфиденциальности. Обязательное — без него
  /// обрабатывать персональные и медицинские данные нельзя.
  final bool policyAccepted;

  String value(RegField field) => values[field] ?? '';
  String? errorOf(RegField field) => fieldErrors[field];

  bool filled(Iterable<RegField> fields) =>
      fields.every((f) => value(f).trim().isNotEmpty);

  RegistrationState copyWith({
    Map<RegField, String>? values,
    Map<RegField, String>? fieldErrors,
    bool? isSubmitting,
    String? formError,
    AppLanguage? language,
    bool? pushConsent,
    bool? policyAccepted,
  }) {
    return RegistrationState(
      values: values ?? this.values,
      // Ошибки не переносятся сами: не передал — значит сняты.
      fieldErrors: fieldErrors ?? const {},
      isSubmitting: isSubmitting ?? this.isSubmitting,
      formError: formError,
      language: language ?? this.language,
      pushConsent: pushConsent ?? this.pushConsent,
      policyAccepted: policyAccepted ?? this.policyAccepted,
    );
  }
}

/// Состояние мастера регистрации целиком: данные копятся между шагами,
/// на сервер уходят одним запросом после шага «Ваши данные».
class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  void setField(RegField field, String value) {
    state = state.copyWith(
      values: {...state.values, field: value},
      fieldErrors: {...state.fieldErrors}..remove(field),
    );
  }

  /// Шаг 1 — почта и пароль. Сервер не трогаем, только проверяем ввод.
  bool submitCredentials() {
    final errors = _collect({
      RegField.email: Validators.email(state.value(RegField.email)),
      RegField.password: Validators.password(state.value(RegField.password)),
      RegField.passwordConfirm: Validators.passwordConfirmation(
        state.value(RegField.passwordConfirm),
        state.value(RegField.password),
      ),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }
    return true;
  }

  /// Шаг 2 — ИИН, ФИО, телефон. Здесь создаётся профиль и уходит СМС.
  Future<bool> submitPersonalData() async {
    if (state.isSubmitting) return false;

    final errors = _collect({
      RegField.iin: Validators.iin(state.value(RegField.iin)),
      RegField.fullName: Validators.fullName(state.value(RegField.fullName)),
      RegField.phone: Validators.phone(state.value(RegField.phone)),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .register(
            email: state.value(RegField.email),
            password: state.value(RegField.password),
            iin: state.value(RegField.iin).trim(),
            fullName: state.value(RegField.fullName).trim(),
            phone: state.value(RegField.phone).trim(),
          );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
      return false;
    }
  }

  /// Шаг 3 — код из СМС. Успех открывает сессию.
  Future<bool> submitCode() async {
    if (state.isSubmitting) return false;

    final errors = _collect({
      RegField.code: Validators.smsCode(state.value(RegField.code)),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyCode(
            phone: state.value(RegField.phone).trim(),
            code: state.value(RegField.code),
          );
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
      return false;
    }
  }

  void setLanguage(AppLanguage language) =>
      state = state.copyWith(values: state.values, language: language);

  void setPushConsent(bool value) => state = state.copyWith(
    values: state.values,
    fieldErrors: state.fieldErrors,
    pushConsent: value,
  );

  void setPolicyAccepted(bool value) => state = state.copyWith(
    values: state.values,
    fieldErrors: state.fieldErrors,
    policyAccepted: value,
  );

  /// Шаг 4 — язык и согласие на рассылки.
  ///
  /// Пройти можно без согласия на push, но не без выбора языка.
  bool submitAppSettings() => state.language != null;

  /// Шаг 5 — принятие политики. Обязательно.
  bool submitPolicy() => state.policyAccepted;

  /// Вызывается после того, как экран показал сообщение об ошибке.
  void formErrorShown() => state = state.copyWith(
    values: state.values,
    fieldErrors: state.fieldErrors,
  );

  Map<RegField, String> _collect(Map<RegField, String?> checks) {
    return {
      for (final entry in checks.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
  }
}

final registrationControllerProvider =
    NotifierProvider<RegistrationController, RegistrationState>(
      RegistrationController.new,
    );
