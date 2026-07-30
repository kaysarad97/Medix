import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../providers/registration_controller.dart';
import '../widgets/otp_code_input.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 3 регистрации — код из СМС.
///
/// Свёрстан по `design/Введите код (ПУСТОЙ).png`.
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

    return RegistrationStepLayout(
      progress: RegistrationProgress.verifyCode,
      title: 'Введите код',
      children: [
        const SizedBox(height: _titleToSubtitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Text('Подтвердите личность', style: AppTypography.subtitle),
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
        const Center(child: _ResendTimer()),
        const SizedBox(height: _timerToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: 'Далее',
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

/// Обратный отсчёт до повторной отправки СМС.
class _ResendTimer extends StatefulWidget {
  const _ResendTimer();

  /// Столько же, сколько показано в макете (00:59).
  static const Duration cooldown = Duration(seconds: 59);

  @override
  State<_ResendTimer> createState() => _ResendTimerState();
}

class _ResendTimerState extends State<_ResendTimer> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _secondsLeft = _ResendTimer.cooldown.inSeconds);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_secondsLeft == 0) {
      return TextButton(
        onPressed: () {
          // TODO(auth): дёрнуть повторную отправку кода, когда появится
          // эндпоинт. Сейчас только перезапускаем отсчёт.
          _start();
        },
        child: Text(
          'выслать СМС-сообщение ещё раз',
          style: AppTypography.captionMuted,
        ),
      );
    }

    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Text(
      'выслать СМС-сообщение еще раз через $minutes:$seconds',
      style: AppTypography.captionMuted,
    );
  }
}
