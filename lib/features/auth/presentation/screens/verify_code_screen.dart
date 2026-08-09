import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/registration_controller.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/otp_resend_timer.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 3 регистрации — код из письма.
///
/// Свёрстан по `design/Введите код (ПУСТОЙ).png`. Отличие от макета: боксов
/// шесть, а не пять — столько цифр в коде, который присылает бэкенд.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  /// Заголовок 261…304 → подзаголовок 322.
  static const double _titleToSubtitle = 17;

  /// Подзаголовок 322…342 → боксы кода 384.
  static const double _subtitleToOtp = 43;

  /// Боксы 384…467 → строка таймера 560.
  static const double _otpToTimer = 93;

  /// Таймер 560…576 → кнопка 631.
  static const double _timerToButton = 55;

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);

    ref.listen(registrationControllerProvider, (previous, next) {
      final error = next.formError;
      if (error != null && error != previous?.formError) {
        showFormErrorSnackBar(context, error);
        controller.formErrorShown();
      }
    });

    final codeError = state.errorOf(RegField.code);
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepLayout(
      progress: RegistrationProgress.verifyCode,
      title: l10n.verifyCodeTitle,
      children: [
        const SizedBox(height: _titleToSubtitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text(
            l10n.verifyCodeSubtitle(state.value(RegField.email)),
            style: AppTypography.subtitle,
          ),
        ),
        const SizedBox(height: _subtitleToOtp),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: OtpCodeInput(
            onChanged: (code) => controller.setField(RegField.code, code),
            onCompleted: (_) => _next(),
          ),
        ),
        if (codeError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              codeError,
              style: AppTypography.captionMuted,
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: _otpToTimer),
        Center(child: OtpResendTimer(onResend: controller.resendCode)),
        const SizedBox(height: _timerToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            trailingIcon: Icons.arrow_forward,
            isLoading: state.isSubmitting,
            onPressed: state.value(RegField.code).isNotEmpty ? _next : null,
          ),
        ),
      ],
    );
  }

  Future<void> _next() async {
    final ok = await ref
        .read(registrationControllerProvider.notifier)
        .submitCode();
    if (ok && mounted) context.push(Routes.appSettings);
  }
}
