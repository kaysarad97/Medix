import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/platform/external_url_opener.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_workflow.dart';
import '../providers/lab_services_providers.dart';

/// Laboratory files uploaded after an order has been completed.
///
/// The API currently exposes the order id and creation date, but not the test
/// name or laboratory name. The screen therefore does not invent metadata and
/// presents each server result as a downloadable document.
class LabResultsScreen extends ConsumerStatefulWidget {
  const LabResultsScreen({super.key});

  @override
  ConsumerState<LabResultsScreen> createState() => _LabResultsScreenState();
}

class _LabResultsScreenState extends ConsumerState<LabResultsScreen> {
  String? _openingResultId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(labResultsProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 36),
            ScreenTopBar(
              title: l10n.labResultsTitle,
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: results.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                error: (_, _) => _MessageState(
                  message: l10n.labResultsLoadError,
                  actionLabel: l10n.labResultsRetryAction,
                  onPressed: () => ref.invalidate(labResultsProvider),
                ),
                data: (items) => items.isEmpty
                    ? _MessageState(message: l10n.labResultsEmpty)
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .refresh(labResultsProvider.future)
                            .then<void>((_) {}),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH,
                            0,
                            AppSpacing.screenH,
                            32,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final result = items[index];
                            return _LabResultCard(
                              result: result,
                              busy: _openingResultId == result.id,
                              onTap: _openingResultId == null
                                  ? () => _open(result)
                                  : null,
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(LabResultFile result) async {
    setState(() => _openingResultId = result.id);
    try {
      final download = await ref.read(
        labResultDownloadProvider(result.id).future,
      );
      final uri = Uri.tryParse(download.url);
      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw const FormatException('Invalid result download URL');
      }
      final opened = await ref.read(externalUrlOpenerProvider)(uri);
      if (!opened && mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.labResultOpenError,
        );
      }
    } catch (_) {
      if (mounted) {
        showFormErrorSnackBar(
          context,
          AppLocalizations.of(context)!.labResultOpenError,
        );
      }
    } finally {
      if (mounted) setState(() => _openingResultId = null);
    }
  }
}

class _LabResultCard extends StatelessWidget {
  const _LabResultCard({
    required this.result,
    required this.busy,
    required this.onTap,
  });

  final LabResultFile result;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat('dd.MM.yyyy, HH:mm').format(result.createdAt);

    return AppCard(
      key: ValueKey('lab-result-${result.id}'),
      color: AppColors.surfaceWhite,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.accentSofter,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.labResultFileTitle,
                        style: AppTypography.titleMd,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.labResultOrderPrefix} ${result.labOrderId}',
                        style: AppTypography.cardItemMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${l10n.labResultDatePrefix} $date',
                        style: AppTypography.cardItemMeta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (busy)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.labResultOpenAction,
                        style: AppTypography.linkSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AppCard(
        color: AppColors.surfaceWhite,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 52,
              color: AppColors.primaryBright,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTypography.bodyMd,
              textAlign: TextAlign.center,
            ),
            if (onPressed != null && actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
