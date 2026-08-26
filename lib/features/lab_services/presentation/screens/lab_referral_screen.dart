import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_workflow.dart';
import '../providers/lab_ocr_providers.dart';

class LabReferralScreen extends ConsumerWidget {
  const LabReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(labOcrControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: l10n.labReferralTitle,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: state.when(
                  loading: () => const _Recognizing(),
                  error: (_, _) => _UploadState(
                    message: l10n.labReferralUploadError,
                    actionLabel: l10n.labReferralRetryAction,
                    onPressed: () =>
                        ref.read(labOcrControllerProvider.notifier).upload(),
                  ),
                  data: (referral) => referral == null
                      ? _UploadState(
                          message: l10n.labReferralDescription,
                          actionLabel: l10n.labReferralChooseAction,
                          onPressed: () => ref
                              .read(labOcrControllerProvider.notifier)
                              .upload(),
                        )
                      : _ReferralResult(referral: referral),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Recognizing extends StatelessWidget {
  const _Recognizing();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          AppLocalizations.of(context)!.labReferralRecognizing,
          style: AppTypography.bodyLg,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _UploadState extends StatelessWidget {
  const _UploadState({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIconChip(icon: MedixIcon.uploadAnalyses, size: 64),
          const SizedBox(height: 20),
          Text(
            message,
            style: AppTypography.bodyLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: actionLabel, onPressed: onPressed),
        ],
      ),
    ),
  );
}

class _ReferralResult extends ConsumerWidget {
  const _ReferralResult({required this.referral});

  final LabReferral referral;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (referral.status == LabReferralStatus.failed) {
      return _UploadState(
        message: referral.failureReason ?? l10n.labReferralRecognitionError,
        actionLabel: l10n.labReferralRetryAction,
        onPressed: () => ref.read(labOcrControllerProvider.notifier).upload(),
      );
    }

    return ListView(
      children: [
        Text(
          l10n.labReferralRecognizedTitle,
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final test in referral.recognizedTests)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    '• ${test['name'] ?? test['title'] ?? '—'}',
                    style: AppTypography.bodyMd,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: l10n.labReferralCompareAction,
          trailingIcon: Icons.arrow_forward,
          onPressed: () =>
              context.push(Routes.labOffersForReferral(referral.id)),
        ),
      ],
    );
  }
}
