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
/// для Gold.
///
/// Два макета — `design/Предоплата - GOLD.png` и
/// `design/Предоплата без подписки.png` — тот же гейт, что и на результатах
/// поиска врача (`DoctorSearchResultsScreen._Price`): скидка и зачёркнутая
/// цена показываются только реальным подписчикам Gold, а не всем подряд.
/// Без подписки — полная цена и кнопка «Оформить подписку» с ценой со
/// скидкой рядом, которая ведёт в общую подписку (это же и закрывает вход
/// в подписку — до сих пор её некуда было открыть нажатием).
///
/// Третий макет, `design/Предоплата.png`, — более ранний черновик без
/// сравнения цены и кнопки подписки; он полностью совпадает с состоянием
/// «нет скидки» ([Appointment.goldPriceLabel] == null), отдельно не
/// реализован.
///
/// Kaspi и Apple Pay проводят оплату своим интерфейсом (см.
/// `PaymentMethod`) — SDK ещё не подключены, поэтому оба ведут в один и тот
/// же мок-результат оплаты, как кнопки на `PaymentMethodScreen`.
class PrepaymentCard extends StatelessWidget {
  const PrepaymentCard({
    super.key,
    required this.appointment,
    required this.isGold,
    this.onPay,
    this.onSubscribe,
  });

  final Appointment appointment;
  final bool isGold;
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

    final gold = appointment.goldPriceLabel;
    final showDiscount = gold != null && !isGold;
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      borderRadius: DoctorMetrics.allRadius,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.prepaymentCardTitle, style: AppTypography.cardTitleAccent),
          const SizedBox(height: 16),
          if (isGold && gold != null) ...[
            _StrikedPrice(label: base),
            const SizedBox(height: 4),
            Center(child: Text('$gold ₸', style: AppTypography.priceHero)),
            const SizedBox(height: 10),
            const Center(child: _GoldPricePill()),
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
          if (showDiscount) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.prepaymentDiscountPrompt,
                style: AppTypography.captionMuted,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StrikedPrice(label: base),
                const SizedBox(width: 12),
                Text('$gold ₸', style: AppTypography.priceHero),
              ],
            ),
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
class _GoldPricePill extends StatelessWidget {
  const _GoldPricePill();

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
          AppLocalizations.of(context)!.goldPricePillLabel,
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
