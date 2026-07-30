import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';

/// Поле ввода кода из СМС.
///
/// Геометрия из `design/Введите код (ПУСТОЙ).png`: пять боксов 70×83
/// с зазором 12, радиус 18, заливка [AppColors.surfaceWhite].
///
/// Эти размеры — максимум, а не константа. В сумме ряд занимает 398, а
/// макет нарисован под ширину 440; на телефоне поуже (у Galaxy S23 FE
/// 393 логических точки) ряд не помещался и вылезал за экран. Поэтому
/// боксы ужимаются под доступную ширину с сохранением пропорции 70:83.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.onChanged,
    this.length = 5,
    this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;

  /// Ширина бокса в макете. Служит верхней границей.
  static const double boxWidth = 70;

  /// Высота бокса в макете. Боксы не квадратные — это замер, не описка.
  static const double boxHeight = 83;

  static const double gap = 12;

  /// Ширина ряда при размерах из макета.
  static double intrinsicWidth(int length) =>
      length * boxWidth + (length - 1) * gap;

  /// Ключ бокса. Нужен тестам: поле внутри сжато по содержимому и его
  /// габариты не совпадают с габаритами бокса.
  static ValueKey<String> boxKey(int index) => ValueKey('otp-box-$index');

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onBoxChanged(int index, String value) {
    // Вставка кода целиком (автозаполнение из СМС) — разносим по боксам.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, widget.length - 1);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  /// Backspace в пустом боксе возвращает фокус на предыдущий.
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      widget.onChanged(_code);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gaps = OtpCodeInput.gap * (widget.length - 1);
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : OtpCodeInput.intrinsicWidth(widget.length);
        final boxWidth = math.min(
          OtpCodeInput.boxWidth,
          (available - gaps) / widget.length,
        );
        final boxHeight =
            boxWidth * OtpCodeInput.boxHeight / OtpCodeInput.boxWidth;

        return _buildRow(boxWidth, boxHeight);
      },
    );
  }

  Widget _buildRow(double boxWidth, double boxHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: OtpCodeInput.gap),
          SizedBox(
            key: OtpCodeInput.boxKey(i),
            width: boxWidth,
            height: boxHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppRadius.allMd,
              ),
              child: Focus(
                onKeyEvent: (_, event) => _onKey(i, event),
                // Center обязателен: при жёстко заданной высоте бокса
                // TextField прижимает цифру к верхней кромке. По горизонтали
                // хватает textAlign, по вертикали — нет.
                child: Center(
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTypography.otpDigit,
                    cursorColor: AppColors.accent,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _onBoxChanged(i, value),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
