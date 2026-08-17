import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../../subscriptions/domain/entities/payment_method.dart';
import 'doctor_metrics.dart';

/// «Предоплата записи» — оплата приёма картой/Kaspi/Apple Pay, со скидкой
/// по подписке.
///
/// Два макета — `design/Предоплата - GOLD.png` и
/// `design/Предоплата без подписки.png`. Что из них показать, решает не
/// клиент, а сервер: цена со скидкой (`price_for_user`) приходит только
/// тому, кому она положена, и `Appointment.subscriberPrice` у остальных
/// пуст. Так же устроены и результаты поиска врача
/// (`DoctorSearchResultsScreen._Price`).
///
/// Третий макет, `design/Предоплата.png`, — более ранний черновик без
/// сравнения цены и кнопки подписки; он полностью совпадает с состоянием
/// «нет скидки», отдельно не реализован.
///
/// Kaspi и Apple Pay проводят оплату своим интерфейсом (см.
/// `PaymentMethod`) — SDK ещё не подключены, поэтому оба ведут в один и тот
/// же мок-результат оплаты, как кнопки на `PaymentMethodScreen`.
class PrepaymentCard extends StatelessWidget {
  const PrepaymentCard({
    super.key,
    required this.appointment,
    this.hasSubscription = false,
    this.onPay,
    this.onSubscribe,
  });

  final Appointment appointment;

  /// Есть ли у пользователя действующая подписка. Нужен только затем, чтобы
  /// не предлагать оформить её тому, кто уже оформил: скидки на эту запись
  /// может не быть и у подписчика — тариф даёт её не на всё.
  final bool hasSubscription;
  final ValueChanged<PaymentMethod>? onPay;
  final VoidCallback? onSubscribe;

  /// Способы оплаты на этом макете — только Kaspi и Apple Pay, в отличие
  /// от полного списка на `design/Оплата.png`.
  static const List<PaymentMethod> _methods = [
    PaymentMethod.kaspi,
    PaymentMethod.applePay,
  ];

  @override
  Widget build(BuildContext context) {
    final base = appointment.basePriceLabel;
    if (base == null) return const SizedBox.shrink();

    // Скидку считает сервер: цена со скидкой приходит только тому, кому она
    // положена. Клиент больше не смотрит на тариф сам — до 17 августа 2026
    // он гейтил показ по `SubscriptionTier.gold`, и подписчик Silver видел
    // полную цену, хотя списывалась с него скидочная.
    final discounted = appointment.subscriberPriceLabel;
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      borderRadius: DoctorMetrics.allRadius,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.prepaymentCardTitle, style: AppTypography.cardTitleAccent),
          const SizedBox(height: 16),
          if (discounted != null) ...[
            _StrikedPrice(label: base),
            const SizedBox(height: 4),
            Center(
              child: Text('$discounted ₸', style: AppTypography.priceHero),
            ),
            const SizedBox(height: 10),
            const Center(child: _SubscriberPricePill()),
            const SizedBox(height: 16),
          ] else ...[
            Center(child: Text('$base ₸', style: AppTypography.priceHero)),
            const SizedBox(height: 16),
          ],
          for (final method in _methods) ...[
            if (method != _methods.first) const SizedBox(height: 8),
            _PaymentRow(
              method: method,
              onTap: onPay == null ? null : () => onPay!(method),
            ),
          ],
          if (discounted == null && !hasSubscription) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.prepaymentDiscountPrompt,
                style: AppTypography.captionMuted,
                textAlign: TextAlign.center,
              ),
            ),
            // Цены со скидкой здесь нет, хотя в макете она есть: сервер
            // считает цену только тому, у кого подписка уже оформлена, и
            // показать «сколько было бы» неоткуда.
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.subscribeButtonLabel,
              onPressed: onSubscribe,
            ),
          ],
        ],
      ),
    );
  }
}

class _StrikedPrice extends StatelessWidget {
  const _StrikedPrice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label ₸',
        style: AppTypography.cardItemMeta.copyWith(
          decoration: TextDecoration.lineThrough,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}

/// Пилюля «Цена с подпиской Gold» под крупной ценой.
class _SubscriberPricePill extends StatelessWidget {
  const _SubscriberPricePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          AppLocalizations.of(context)!.subscriberPricePillLabel,
          style: AppTypography.goldLabel.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.method, this.onTap});

  final PaymentMethod method;
  final VoidCallback? onTap;

  static const double _height = 60;
  static const double _logoSize = 36;

  static String _labelFor(PaymentMethod method, AppLocalizations l10n) =>
      switch (method) {
        PaymentMethod.kaspi => l10n.paymentMethodKaspi,
        PaymentMethod.halyk => l10n.paymentMethodHalyk,
        PaymentMethod.applePay => l10n.paymentMethodApplePay,
        PaymentMethod.otherBank => l10n.paymentMethodOtherBank,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: DoctorMetrics.allRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                SizedBox(
                  width: _logoSize,
                  height: _logoSize,
                  child: Center(
                    child: BrandIcon(icon: method.icon, size: _logoSize),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _labelFor(method, l10n),
                    style: AppTypography.bodyMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
