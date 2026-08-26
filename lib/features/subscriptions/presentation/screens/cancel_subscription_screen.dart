import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/subscription_plan.dart';
import '../providers/subscriptions_providers.dart';

/// Подтверждение отказа от автоматического продления подписки.
///
/// Сервер не отключает уже оплаченный доступ немедленно, поэтому успешное
/// состояние обязательно показывает фактическую дату окончания периода.
class CancelSubscriptionScreen extends ConsumerStatefulWidget {
  const CancelSubscriptionScreen({super.key, this.onCancelled});

  final ValueChanged<SubscriptionCancellation>? onCancelled;

  @override
  ConsumerState<CancelSubscriptionScreen> createState() =>
      _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState
    extends ConsumerState<CancelSubscriptionScreen> {
  bool loading = false;
  SubscriptionCancellation? cancellation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 36),
            ScreenTopBar(
              title: l10n.cancelSubscriptionTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cancellation == null
                          ? Icons.event_busy_outlined
                          : Icons.check_circle_outline,
                      size: 72,
                      color: AppColors.primaryBright,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      cancellation == null
                          ? l10n.cancelSubscriptionPrompt
                          : l10n.subscriptionCancelledMessage(
                              _formatDate(cancellation!.periodEnd),
                            ),
                      style: AppTypography.bodyMd,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (cancellation == null) ...[
                      PrimaryButton(
                        label: l10n.cancelSubscriptionAction,
                        isLoading: loading,
                        onPressed: loading ? null : _cancel,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        child: Text(l10n.keepSubscriptionAction),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    setState(() => loading = true);
    try {
      final result = await ref.read(subscriptionsRepositoryProvider).cancel();
      if (!mounted) return;
      setState(() => cancellation = result);
      widget.onCancelled?.call(result);
    } catch (_) {
      if (mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.cancelSubscriptionError,
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
