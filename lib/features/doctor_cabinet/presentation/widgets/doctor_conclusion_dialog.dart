import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

Future<String?> showDoctorConclusionDialog(
  BuildContext context, {
  String? initialText,
}) => showDialog<String>(
  context: context,
  builder: (_) => DoctorConclusionDialog(initialText: initialText),
);

class DoctorConclusionDialog extends StatefulWidget {
  const DoctorConclusionDialog({super.key, this.initialText});

  final String? initialText;

  @override
  State<DoctorConclusionDialog> createState() => _DoctorConclusionDialogState();
}

class _DoctorConclusionDialogState extends State<DoctorConclusionDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text.trim();

    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
      title: Text(
        l10n.doctorConclusionDialogTitle,
        style: AppTypography.titleMd,
      ),
      content: TextField(
        key: const ValueKey('doctor-conclusion-text'),
        controller: _controller,
        autofocus: true,
        minLines: 5,
        maxLines: 10,
        maxLength: 4000,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l10n.doctorConclusionTextHint,
          filled: true,
          fillColor: AppColors.surface,
          border: const OutlineInputBorder(
            borderRadius: AppRadius.allMd,
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('doctor-conclusion-save'),
          onPressed: text.isEmpty
              ? null
              : () => Navigator.of(context).pop(text),
          child: Text(l10n.saveButtonLabel),
        ),
      ],
    );
  }
}
