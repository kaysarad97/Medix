import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../profile/presentation/widgets/profile_metrics.dart';
import '../../domain/entities/payment_method.dart';

/// «Выберите метод оплаты» — свёрстан по `design/Оплата.png`.
class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({
    super.key,
    this.onMethodSelected,
    this.onSavedCards,
  });

  final ValueChanged<PaymentMethod>? onMethodSelected;
  final VoidCallback? onSavedCards;

  static const double rowHeight = 74;

  @override
  Widget build(BuildContext context) {
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
                title: 'Выберите метод оплаты',
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 42),
              _Section(
                child: AppCard(
                  borderRadius: ProfileMetrics.allRadius,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final method in PaymentMethod.values) ...[
                        if (method != PaymentMethod.values.first)
                          const SizedBox(height: 8),
                        _MethodRow(
                          icon: method.icon,
                          label: method.label,
                          onTap: () => onMethodSelected?.call(method),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _Section(
                child: AppCard(
                  borderRadius: ProfileMetrics.allRadius,
                  padding: const EdgeInsets.all(8),
                  child: _MethodRow(
                    icon: MedixIcon.paymentCard,
                    label: 'Сохраненные карты',
                    onTap: onSavedCards,
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

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.icon, required this.label, this.onTap});

  final MedixIcon icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: ProfileMetrics.allRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: PaymentMethodScreen.rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Логотипы банков идут своими цветами — перекрашивать их
                // нельзя, поэтому не AppIcon с фильтром, а картинка как есть.
                _BrandLogo(icon: icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const AppIcon(
                  icon: MedixIcon.chevronRight,
                  size: ProfileMetrics.chevronSize,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Логотип платёжной системы в исходных цветах.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.icon});

  final MedixIcon icon;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: BrandIcon(
          icon: icon,
          size: icon == MedixIcon.paymentCard ? 30 : size,
        ),
      ),
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
