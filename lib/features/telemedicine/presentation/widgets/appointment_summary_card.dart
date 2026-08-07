import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import 'doctor_metrics.dart';

/// Строка «что и когда» на экране записи: формат приёма слева, дата справа.
class AppointmentSummaryCard extends StatelessWidget {
  const AppointmentSummaryCard({super.key, required this.appointment});

  final Appointment appointment;

  static const double iconSize = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: DoctorMetrics.summaryHeight,
      child: AppCard(
        color: AppColors.surfaceWhite,
        borderRadius: DoctorMetrics.allRadius,
        padding: const EdgeInsets.only(left: 13, right: 24),
        child: Row(
          children: [
            const AppIconChip(
              icon: MedixIcon.mail,
              size: iconSize,
              background: AppColors.accentSofter,
              foreground: AppColors.primaryBright,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment.kind.label,
                    style: AppTypography.actionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.appointmentTitle,
                    style: AppTypography.tileSubtitle.copyWith(
                      color: AppColors.primaryBright,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              appointment.dayMonthTime,
              style: AppTypography.actionTitle,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
