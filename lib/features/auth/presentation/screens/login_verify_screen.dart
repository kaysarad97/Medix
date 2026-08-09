import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/login_controller.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/otp_resend_timer.dart';

/// Экран входа — шаг 2: код из письма.
///
/// Отдельный экран, а не переиспользованный шаг регистрации: у того есть
/// полоса прогресса мастера, и здесь она была бы враньём — вход из пяти
/// шагов не состоит.
class LoginVerifyScreen extends ConsumerStatefulWidget {
  const LoginVerifyScreen({super.key});

  @override
  ConsumerState<LoginVerifyScreen> createState() => _LoginVerifyScreenState();
}

class _LoginVerifyScreenState extends ConsumerState<LoginVerifyScreen> {
  /// Отступы взяты с шага «Введите код» мастера регистрации, за вычетом
  /// полосы прогресса: заголовок встаёт на её место.
  static const double _titleTop = 189;
  static const double _titleToSubtitle = 17;
  static const double _subtitleToOtp = 43;
  static const double _otpToTimer = 93;
  static const double _timerToButton = 55;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(loginControllerProvider.notifier);
    final state = ref.watch(loginControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(loginControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        context.go(Routes.home);
        return;
      }

      final error = next.formError;
      if (error != null && error != previous?.formError) {
        showFormErrorSnackBar(context, error);
        controller.formErrorShown();
      }
    });

    return AppScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _titleTop),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(l10n.verifyCodeTitle, style: AppTypography.h1),
              ),
              const SizedBox(height: _titleToSubtitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(
                  l10n.verifyCodeSubtitle(state.email),
                  style: AppTypography.subtitle,
                ),
              ),
              const SizedBox(height: _subtitleToOtp),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: OtpCodeInput(
                  onChanged: controller.codeChanged,
                  onCompleted: (_) => controller.submitCode(),
                ),
              ),
              if (state.codeError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Text(
                    state.codeError!,
                    style: AppTypography.captionMuted,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: _otpToTimer),
              Center(child: OtpResendTimer(onResend: controller.resendCode)),
              const SizedBox(height: _timerToButton),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: l10n.loginButtonLabel,
                  size: PrimaryButtonSize.large,
                  color: AppColors.primary,
                  isLoading: state.isSubmitting,
                  onPressed: state.canSubmitCode ? controller.submitCode : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
