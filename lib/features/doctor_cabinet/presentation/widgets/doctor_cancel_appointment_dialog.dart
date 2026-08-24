import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

Future<String?> showDoctorCancelAppointmentDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const DoctorCancelAppointmentDialog(),
    );

/// Backend требует непустую причину отмены, поэтому действие из макета
/// подтверждается короткой формой перед сетевым запросом.
class DoctorCancelAppointmentDialog extends StatefulWidget {
  const DoctorCancelAppointmentDialog({super.key});

  @override
  State<DoctorCancelAppointmentDialog> createState() =>
      _DoctorCancelAppointmentDialogState();
}

class _DoctorCancelAppointmentDialogState
    extends State<DoctorCancelAppointmentDialog> {
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
      title: Text(
        l10n.doctorCancelAppointmentDialogTitle,
        style: AppTypography.titleMd,
      ),
      content: TextField(
        key: const ValueKey('doctor-cancel-reason'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 6,
        maxLength: 500,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: l10n.doctorCancelAppointmentReasonHint,
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
          key: const ValueKey('doctor-cancel-confirm'),
          onPressed: reason.isEmpty
              ? null
              : () => Navigator.of(context).pop(reason),
          child: Text(l10n.doctorCancelAppointmentConfirm),
        ),
      ],
    );
  }
}
