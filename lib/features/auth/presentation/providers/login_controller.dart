import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/app_user.dart';
import 'auth_providers.dart';

@immutable
class LoginState {
  const LoginState({
    this.email = '',
    this.code = '',
    this.emailError,
    this.codeError,
    this.formError,
    this.isSubmitting = false,
    this.isCodeSent = false,
    this.isAuthenticated = false,
    this.userRole,
  });

  final String email;
  final String code;

  final String? emailError;
  final String? codeError;

  /// Ошибка, не привязанная к полю (отказ сервера, нет сети).
  final String? formError;

  final bool isSubmitting;

  /// Первый шаг пройден — сервер принял адрес и отправил письмо.
  final bool isCodeSent;

  final bool isAuthenticated;
  final AppUserRole? userRole;

  bool get canSubmitEmail => email.trim().isNotEmpty && !isSubmitting;
  bool get canSubmitCode => code.trim().isNotEmpty && !isSubmitting;

  /// Внимание: поля ошибок НЕ переносятся из предыдущего состояния —
  /// не передал явно, значит ошибка снята. Так правка любого поля сама
  /// гасит свою ошибку, и не нужно отдельного `clearErrors()`.
  LoginState copyWith({
    String? email,
    String? code,
    String? emailError,
    String? codeError,
    String? formError,
    bool? isSubmitting,
    bool? isCodeSent,
    bool? isAuthenticated,
    AppUserRole? userRole,
  }) {
    return LoginState(
      email: email ?? this.email,
      code: code ?? this.code,
      emailError: emailError,
      codeError: codeError,
      formError: formError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
    );
  }
}

/// Вход в два шага: адрес → код из письма.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Ошибки сбрасываются при правке поля — переваливать их на пользователя
  /// пока он печатает не нужно.
  void emailChanged(String value) {
    state = state.copyWith(email: value, codeError: state.codeError);
  }

  void codeChanged(String value) {
    state = state.copyWith(code: value, emailError: state.emailError);
  }

  /// Шаг 1 — просим сервер отправить код.
  ///
  /// Успех здесь не означает, что аккаунт существует: сервер отвечает
  /// одинаково на любой адрес, чтобы по нему нельзя было проверять,
  /// зарегистрирован ли человек. Про несуществующий адрес пользователь
  /// узнает только на шаге с кодом.
  Future<bool> submitEmail() async {
    if (state.isSubmitting) return false;

    final emailError = Validators.email(state.email);
    if (emailError != null) {
      state = state.copyWith(emailError: emailError);
      return false;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .loginStart(email: state.email.trim());
      state = state.copyWith(isSubmitting: false, isCodeSent: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
      return false;
    }
  }

  /// Повторная отправка кода с экрана ввода — тот же запрос, что и шаг 1.
  Future<bool> resendCode() async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .loginStart(email: state.email.trim());
      state = state.copyWith(isSubmitting: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
      return false;
    }
  }

  /// Шаг 2 — обмениваем код на сессию.
  Future<void> submitCode() async {
    if (state.isSubmitting) return;

    final codeError = Validators.otpCode(state.code);
    if (codeError != null) {
      state = state.copyWith(codeError: codeError);
      return;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .loginVerify(email: state.email.trim(), code: state.code);
      state = state.copyWith(
        isSubmitting: false,
        isAuthenticated: true,
        userRole: session.user.role,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, formError: e.message);
    }
  }

  /// Вызывается после того, как экран показал сообщение об ошибке.
  void formErrorShown() => state = state.copyWith(formError: null);
}

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);
