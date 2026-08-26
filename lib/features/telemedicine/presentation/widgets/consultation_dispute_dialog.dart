import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

Future<String?> showConsultationDisputeDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const ConsultationDisputeDialog(),
    );

class ConsultationDisputeDialog extends StatefulWidget {
  const ConsultationDisputeDialog({super.key});

  @override
  State<ConsultationDisputeDialog> createState() =>
      _ConsultationDisputeDialogState();
}

class _ConsultationDisputeDialogState extends State<ConsultationDisputeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reason = _controller.text.trim();

    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      title: Text(l10n.consultationDisputeTitle, style: AppTypography.titleMd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.consultationDisputePrompt, style: AppTypography.bodyMd),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('consultation-dispute-reason'),
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.consultationDisputeHint,
              filled: true,
              fillColor: AppColors.surface,
              border: const OutlineInputBorder(
                borderRadius: AppRadius.allMd,
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('consultation-dispute-submit'),
          onPressed: reason.isEmpty
              ? null
              : () => Navigator.of(context).pop(reason),
          child: Text(l10n.consultationDisputeSubmit),
        ),
      ],
    );
  }
}
