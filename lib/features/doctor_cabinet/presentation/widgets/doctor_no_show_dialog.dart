import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Подтверждение неявки — проще `DoctorCancelAppointmentDialog`: бэкенд не
/// просит причину (`PATCH .../no-show` без тела), поэтому текстового поля
/// нет, только да/нет. Оформление то же самое (`AppRadius.allLg`,
/// `AppTypography.titleMd`, `FilledButton`) для единого вида диалогов
/// кабинета врача.
Future<bool> showDoctorNoShowDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        title: Text(l10n.doctorNoShowDialogTitle, style: AppTypography.titleMd),
        content: Text(l10n.doctorNoShowDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButtonLabel),
          ),
          FilledButton(
            key: const ValueKey('doctor-no-show-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.doctorNoShowConfirm),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
