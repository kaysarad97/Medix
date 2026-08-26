import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/medix_wait_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/profile_metrics.dart';
import '../../data/repositories/subscriptions_repository.dart';
import '../../domain/entities/payment_method.dart';
import '../providers/subscriptions_providers.dart';

/// Ввод данных карты — свёрстан по `design/Ввод данных карты.png`.
///
/// Данные карты никуда не сохраняются: объект [CardDetails] живёт до
/// отправки в шлюз и умирает вместе с экраном. Ни secure storage, ни
/// логов, ни нашего бэкенда — хранение данных держателя карты требует
/// сертификации PCI DSS.
class CardFormScreen extends ConsumerStatefulWidget {
  const CardFormScreen({
    super.key,
    this.onResult,
    this.onSubmit,
    this.animatedWait = true,
  });

  final ValueChanged<PaymentOutcome>? onResult;

  /// Что происходит по кнопке «Далее» вместо оформления подписки.
  ///
  /// `null` — прежнее поведение: `subscriptionsRepositoryProvider.pay()`.
  /// Нужен регистрации врача-фрилансера: там тот же экран собирает
  /// банковские данные (`design/Ввод данных карты.png`), но это задел на
  /// будущую монетизацию, а не оплата — своего эндпоинта под сохранение
  /// карты врача нет, и дёргать `pay()` с чужим тарифом было бы неверно
  /// по смыслу.
  final Future<PaymentOutcome> Function(CardDetails card)? onSubmit;

  /// Крутить анимацию на экране ожидания.
  ///
  /// Выключается в тестах: анимированная гифка планирует кадры таймером,
  /// который не останавливается, и виджет-тест не может завершиться —
  /// падает на «A Timer is still pending».
  final bool animatedWait;

  @override
  ConsumerState<CardFormScreen> createState() => _CardFormScreenState();
}

class _CardFormScreenState extends ConsumerState<CardFormScreen> {
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  var _paying = false;

  /// Экран ожидания держится не меньше этого времени.
  ///
  /// Заглушка отвечает за 300 мс, и без задержки «подождите...» мигнуло бы
  /// и пропало — читается как сбой, а не как проверка.
  static const Duration _minimumWait = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    for (final c in [_number, _holder, _expiry, _cvv]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  CardDetails get _card => CardDetails(
    number: _number.text,
    holder: _holder.text,
    expiry: _expiry.text,
    cvv: _cvv.text,
  );

  /// Прежнее поведение: оформление подписки. Используется, когда
  /// [CardFormScreen.onSubmit] не передан.
  Future<PaymentOutcome> _pay() async {
    final outcome = await ref
        .read(subscriptionsRepositoryProvider)
        .pay(_card, tier: ref.read(selectedPlanProvider));

    // Тариф в шапке профиля и платные разделы (семья, история замеров)
    // смотрят на подписку из `/users/me`; после оформления её надо
    // перечитать, иначе до перезапуска приложение считает, что подписки
    // нет. Ровно так уже терялись данные на живом сервере.
    if (outcome == PaymentOutcome.success) ref.invalidate(profileProvider);
    return outcome;
  }

  Future<void> _submit() async {
    setState(() => _paying = true);
    final started = DateTime.now();

    final outcome = await (widget.onSubmit?.call(_card) ?? _pay());

    final left = _minimumWait - DateTime.now().difference(started);
    if (left > Duration.zero) await Future<void>.delayed(left);

    if (!mounted) return;
    setState(() => _paying = false);
    widget.onResult?.call(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_paying) {
      // Экран ожидания по `design/Подождите....png`. Показываем его прямо
      // здесь, а не отдельным маршрутом: иначе данные карты пришлось бы
      // передавать между экранами, а им место только в этом виджете.
      return MedixWaitView(
        animated: widget.animatedWait,
        title: l10n.waitingTitle,
        subtitle: l10n.waitingCardSubtitle,
      );
    }

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: l10n.choosePaymentMethodTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 26),
              _Section(child: _CardPreview(card: _card)),
              const SizedBox(height: 22),
              _Section(
                child: Text(
                  l10n.bankDetailsTitle,
                  style: AppTypography.h2.copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(height: 18),
              _Section(
                child: _Field(
                  label: l10n.cardNumberLabel,
                  controller: _number,
                  keyboardType: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Section(
                child: _Field(label: l10n.cardHolderLabel, controller: _holder),
              ),
              const SizedBox(height: 14),
              _Section(
                child: Row(
                  children: [
                    Expanded(
                      child: _Field(
                        label: l10n.cardExpiryLabel,
                        controller: _expiry,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _Field(
                        label: l10n.cardCvvLabel,
                        controller: _cvv,
                        obscure: true,
                        keyboardType: TextInputType.number,
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              _Section(
                child: Center(
                  child: SizedBox(
                    width: PrimaryButton.mediumWidth,
                    child: PrimaryButton(
                      label: l10n.nextButtonLabel,
                      trailingIcon: Icons.arrow_forward,
                      isLoading: _paying,
                      onPressed: _card.isComplete ? _submit : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Карта-превью над формой: показывает то, что уже введено.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.card});

  final CardDetails card;

  static const double height = 216;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Из-под верхней карты выглядывает вторая — так в макете.
          Positioned(
            left: 20,
            right: 20,
            top: 0,
            height: 60,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.primaryBright,
                borderRadius: ProfileMetrics.allRadius,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 24,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.accentSofter,
                borderRadius: ProfileMetrics.allRadius,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Card number', style: AppTypography.tileSubtitle),
                    const SizedBox(height: 8),
                    _Chip(
                      width: double.infinity,
                      child: Text(_maskedNumber, style: AppTypography.bodyMd),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: AppTypography.tileSubtitle,
                            ),
                            const SizedBox(height: 8),
                            _Chip(
                              width: 70,
                              // Через FittedBox: плашка снята с макета, где
                              // в ней стояло «01/01», а единица узкая — с
                              // настоящим сроком («01/30») текст переносился
                              // и последняя цифра уезжала на вторую строку.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _maskedExpiry,
                                  maxLines: 1,
                                  style: AppTypography.bodyMd,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CVV', style: AppTypography.tileSubtitle),
                            const SizedBox(height: 8),
                            _Chip(
                              width: 60,
                              child: Text(
                                '•' * (card.cvv.isEmpty ? 3 : card.cvv.length),
                                style: AppTypography.bodyMd,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Первые двенадцать цифр закрыты точками, последние четыре видны —
  /// как в макете и как принято в платёжных формах.
  String get _maskedNumber {
    final last = card.lastFour;
    final dots = List.filled(3, '••••').join(' ');
    return last.isEmpty ? '$dots ••••' : '$dots $last';
  }

  String get _maskedExpiry {
    final digits = card.expiry.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '01/01';
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.child, required this.width});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.keyboardType,
    this.formatters,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardItemMeta),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withValues(alpha: 0.6),
              borderRadius: ProfileMetrics.allRadius,
              border: Border.all(color: AppColors.divider),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  inputFormatters: formatters,
                  style: AppTypography.bodyMd,
                  cursorColor: AppColors.accent,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ProfileMetrics.screenH),
      child: child,
    );
  }
}
