import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import 'home_metrics.dart';

/// «Предстоящие записи» — заголовок с иконкой и список ближайших приёмов.
class UpcomingAppointmentsCard extends StatelessWidget {
  const UpcomingAppointmentsCard({
    super.key,
    required this.appointments,
    this.onAppointmentTap,
  });

  final List<Appointment> appointments;
  final ValueChanged<Appointment>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(HomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIconChip(icon: MedixIcon.calendar),
              const SizedBox(width: 18),
              Text(
                l10n.upcomingAppointmentsTitle,
                style: AppTypography.sectionTitle,
              ),
            ],
          ),
          const SizedBox(height: HomeMetrics.doctorsTitleToList),
          for (final appointment in appointments) ...[
            if (appointment != appointments.first)
              const SizedBox(height: HomeMetrics.appointmentRowGap),
            _AppointmentRow(
              appointment: appointment,
              onTap: () => onAppointmentTap?.call(appointment),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeMetrics.appointmentRowHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                const AppIconChip(
                  icon: MedixIcon.appointment,
                  size: 40,
                  background: AppColors.surfaceInfo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.specialty, style: AppTypography.bodyMd),
                      const SizedBox(height: 2),
                      Text(
                        appointment.kind.label,
                        style: AppTypography.tileSubtitle,
                      ),
                    ],
                  ),
                ),
                _DatePill(text: appointment.shortDate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: HomeMetrics.datePillSize.width,
      height: HomeMetrics.datePillSize.height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: AppRadius.allPill,
        ),
        child: Center(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
