import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/repositories/subscriptions_repository.dart';

/// Итог оплаты — свёрстан по `design/Оплата прошла.png` и
/// `design/Оплата НЕ прошла.png`.
///
/// Экран один на оба исхода: макеты отличаются только знаком в кружке,
/// надписью и подписью на кнопке. Цвет тот же — состояние передаётся
/// знаком и текстом, а не краснотой; поэтому [AppColors.error] здесь не
/// используется.
class PaymentResultScreen extends StatelessWidget {
  const PaymentResultScreen({
    super.key,
    required this.outcome,
    this.onContinue,
  });

  final PaymentOutcome outcome;

  /// «На главную страницу» при успехе, «Попробовать еще раз» при отказе.
  final VoidCallback? onContinue;

  bool get _ok => outcome == PaymentOutcome.success;

  String get message =>
      _ok ? 'Карта успешно сохранена!' : 'Неверные данные карты';

  String get action => _ok ? 'На главную страницу' : 'Попробовать еще раз';

  /// Замеры по макету: круг 183 с центром на 220, надпись на 655, кнопка
  /// 330×55 на 826. Безопасная зона сверху 62.
  static const double circleSize = 183;
  static const double circleStroke = 5;
  static const double topToCircle = 266;
  static const double circleToMessage = 140;
  static const double bottomInset = 76;

  @override
  Widget build(BuildContext context) {
    // Фон сплошной, без градиента и картинки — на обоих макетах это ровная
    // заливка на весь экран.
    return ColoredBox(
      color: AppColors.accentSofter,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            // Растягиваем по ширине: иначе колонка сжимается до самого
            // широкого потомка и всё содержимое уезжает влево.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: topToCircle),
              Center(child: _Mark(ok: _ok)),
              const SizedBox(height: circleToMessage),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(fontSize: 20),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: PrimaryButton.mediumWidth,
                  child: PrimaryButton(
                    label: action,
                    trailingIcon: Icons.arrow_forward,
                    onPressed: onContinue,
                  ),
                ),
              ),
              const SizedBox(height: bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кружок с галочкой или крестом.
class _Mark extends StatelessWidget {
  const _Mark({required this.ok});

  final bool ok;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PaymentResultScreen.circleSize,
      height: PaymentResultScreen.circleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryBright,
            width: PaymentResultScreen.circleStroke,
          ),
        ),
        child: Icon(
          ok ? Icons.check : Icons.close,
          size: 84,
          color: AppColors.primaryBright,
        ),
      ),
    );
  }
}
