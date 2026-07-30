import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/validators.dart';
import 'auth_providers.dart';

@immutable
class LoginState {
  const LoginState({
    this.identifier = '',
    this.password = '',
    this.identifierError,
    this.passwordError,
    this.formError,
    this.isSubmitting = false,
    this.isAuthenticated = false,
  });

  final String identifier;
  final String password;

  /// Ошибка поля «E-mail или ИИН».
  final String? identifierError;
  final String? passwordError;

  /// Ошибка, не привязанная к полю (отказ сервера, нет сети).
  final String? formError;

  final bool isSubmitting;
  final bool isAuthenticated;

  bool get canSubmit =>
      identifier.trim().isNotEmpty && password.isNotEmpty && !isSubmitting;

  /// Внимание: поля ошибок НЕ переносятся из предыдущего состояния —
  /// не передал явно, значит ошибка снята. Так правка любого поля сама
  /// гасит свою ошибку, и не нужно отдельного `clearErrors()`.
  LoginState copyWith({
    String? identifier,
    String? password,
    String? identifierError,
    String? passwordError,
    String? formError,
    bool? isSubmitting,
    bool? isAuthenticated,
  }) {
    return LoginState(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      identifierError: identifierError,
      passwordError: passwordError,
      formError: formError,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  /// Ошибки сбрасываются при правке поля — переваливать их на пользователя
  /// пока он печатает не нужно.
  void identifierChanged(String value) {
    state = state.copyWith(
      identifier: value,
      passwordError: state.passwordError,
    );
  }

  void passwordChanged(String value) {
    state = state.copyWith(
      password: value,
      identifierError: state.identifierError,
    );
  }

  Future<void> submit() async {
    if (state.isSubmitting) return;

    final identifierError = Validators.emailOrIin(state.identifier);
    final passwordError = Validators.password(state.password);

    if (identifierError != null || passwordError != null) {
      state = state.copyWith(
        identifierError: identifierError,
        passwordError: passwordError,
      );
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      await ref
          .read(authRepositoryProvider)
          .login(identifier: state.identifier.trim(), password: state.password);
      state = state.copyWith(isSubmitting: false, isAuthenticated: true);
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
