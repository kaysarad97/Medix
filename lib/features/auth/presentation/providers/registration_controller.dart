import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/models/app_language.dart';
import 'auth_providers.dart';

/// Текстовые поля мастера регистрации.
enum RegField { email, fullName, birthDate, code }

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
    this.codeTtlSeconds = 0,
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

  /// Сколько живёт отправленный код, по данным сервера. Экран ввода кода
  /// показывает по нему, когда код протухнет.
  final int codeTtlSeconds;

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
    int? codeTtlSeconds,
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
      codeTtlSeconds: codeTtlSeconds ?? this.codeTtlSeconds,
    );
  }
}

/// Состояние мастера регистрации целиком.
///
/// Данные копятся между шагами и уходят на сервер одним запросом после шага
/// «Ваши данные»: бэкенд заводит заявку и отправляет код только когда знает
/// и почту, и имя, и дату рождения.
class RegistrationController extends Notifier<RegistrationState> {
  @override
  RegistrationState build() => const RegistrationState();

  void setField(RegField field, String value) {
    state = state.copyWith(
      values: {...state.values, field: value},
      fieldErrors: {...state.fieldErrors}..remove(field),
    );
  }

  /// Шаг 1 — почта. Сервер не трогаем, только проверяем ввод: узнать, занят
  /// ли адрес, всё равно можно лишь на следующем шаге.
  bool submitEmail() {
    final errors = _collect({
      RegField.email: Validators.email(state.value(RegField.email)),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }
    return true;
  }

  /// Шаг 2 — ФИО и дата рождения. Здесь создаётся заявка и уходит письмо.
  Future<bool> submitPersonalData() async {
    if (state.isSubmitting) return false;

    final errors = _collect({
      RegField.fullName: Validators.fullName(state.value(RegField.fullName)),
      RegField.birthDate: Validators.birthDate(state.value(RegField.birthDate)),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    return _requestCode();
  }

  /// Повторная отправка кода с экрана ввода.
  ///
  /// Это тот же запрос, что и на шаге 2: у бэкенда нет отдельного эндпоинта
  /// «отправить ещё раз», заявка просто перезаписывается.
  Future<bool> resendCode() => _requestCode();

  Future<bool> _requestCode() async {
    state = state.copyWith(isSubmitting: true);
    try {
      final ttl = await ref
          .read(authRepositoryProvider)
          .registerStart(
            email: state.value(RegField.email).trim(),
            fullName: state.value(RegField.fullName).trim(),
            birthDate: DateTime.parse(state.value(RegField.birthDate)),
          );
      state = state.copyWith(isSubmitting: false, codeTtlSeconds: ttl);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
      return false;
    }
  }

  /// Шаг 3 — код из письма. Успех открывает сессию.
  Future<bool> submitCode() async {
    if (state.isSubmitting) return false;

    final errors = _collect({
      RegField.code: Validators.otpCode(state.value(RegField.code)),
    });

    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .registerVerify(
            email: state.value(RegField.email).trim(),
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
