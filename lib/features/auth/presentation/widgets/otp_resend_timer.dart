import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Обратный отсчёт до повторной отправки кода.
///
/// Отсчёт равен паузе, которую держит бэкенд: попросить код раньше нельзя —
/// сервер ответит 429 и скажет, сколько ещё ждать. Поэтому кнопка появляется
/// только когда отсчёт дошёл до нуля.
///
/// Общий для входа и регистрации: письмо там отправляется разными запросами,
/// но ведёт себя одинаково, поэтому конкретный запрос приходит через
/// [onResend].
class OtpResendTimer extends StatefulWidget {
  const OtpResendTimer({
    super.key,
    required this.onResend,
    this.cooldown = AppConstants.otpResendCooldown,
  });

  /// Возвращает `true`, если письмо действительно ушло. Только тогда отсчёт
  /// стартует заново — иначе после сетевой ошибки пользователь остался бы с
  /// минутой ожидания за чужую вину.
  final Future<bool> Function() onResend;

  final Duration cooldown;

  @override
  State<OtpResendTimer> createState() => _OtpResendTimerState();
}

class _OtpResendTimerState extends State<OtpResendTimer> {
  late int _secondsLeft;
  Timer? _timer;
  bool _sending = false;

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
    setState(() => _secondsLeft = widget.cooldown.inSeconds);
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

  Future<void> _resend() async {
    if (_sending) return;
    setState(() => _sending = true);
    final sent = await widget.onResend();
    if (!mounted) return;
    setState(() => _sending = false);
    if (sent) _start();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_secondsLeft == 0) {
      return TextButton(
        onPressed: _sending ? null : _resend,
        child: Text(l10n.resendCodeNow, style: AppTypography.captionMuted),
      );
    }

    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Text(
      l10n.resendCodeCountdown('$minutes:$seconds'),
      style: AppTypography.captionMuted,
    );
  }
}
