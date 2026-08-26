import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';

class AppointmentStatusCard extends StatelessWidget {
  const AppointmentStatusCard({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cancellationReason = appointment.cancellationReason;
    final (:title, :message) = switch (appointment.status) {
      AppointmentStatus.cancelled => (
        title: l10n.appointmentCancelledTitle,
        message: cancellationReason == null || cancellationReason.isEmpty
            ? l10n.appointmentCancelledNoReason
            : l10n.appointmentCancellationReason(cancellationReason),
      ),
      AppointmentStatus.noShow => (
        title: l10n.appointmentNoShowTitle,
        message: l10n.appointmentNoShowMessage,
      ),
      _ => (
        title: l10n.appointmentCompletedTitle,
        message: l10n.appointmentCompletedMessage,
      ),
    };

    return AppCard(
      color: AppColors.surfaceInfo,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primaryBright,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                const SizedBox(height: 6),
                Text(message, style: AppTypography.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
