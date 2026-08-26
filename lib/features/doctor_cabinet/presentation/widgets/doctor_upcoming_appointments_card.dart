import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor_appointment.dart';
import 'doctor_home_metrics.dart';

/// «Предстоящие записи» на главной кабинета врача — тот же заголовок и
/// список, что у пациентской `UpcomingAppointmentsCard`, но строка
/// показывает имя пациента, а не специальность, и открывает не запись, а
/// её карточку со стороны врача — своего маршрута для этого ещё нет.
class DoctorUpcomingAppointmentsCard extends StatelessWidget {
  const DoctorUpcomingAppointmentsCard({
    super.key,
    required this.appointments,
    this.onSeeAll,
    this.onAppointmentTap,
  });

  final List<DoctorAppointment> appointments;
  final VoidCallback? onSeeAll;
  final ValueChanged<DoctorAppointment>? onAppointmentTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(DoctorHomeMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            icon: MedixIcon.calendar,
            title: l10n.upcomingAppointmentsTitle,
            onTap: onSeeAll,
          ),
          const SizedBox(height: DoctorHomeMetrics.appointmentsTitleToList),
          for (final appointment in appointments) ...[
            if (appointment != appointments.first)
              const SizedBox(height: DoctorHomeMetrics.appointmentRowGap),
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

  final DoctorAppointment appointment;
  final VoidCallback? onTap;

  static String _labelFor(AppointmentKind kind, AppLocalizations l10n) =>
      switch (kind) {
        AppointmentKind.videoCall => l10n.videoCallSubtitle,
        AppointmentKind.audioCall => l10n.audioCallLabel,
        AppointmentKind.chat => l10n.chatAppointmentLabel,
        AppointmentKind.inPerson => l10n.inPersonAppointmentLabel,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: DoctorHomeMetrics.appointmentRowHeight,
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
                  icon: MedixIcon.appointmentPulse,
                  size: 40,
                  background: AppColors.surfaceInfo,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labelFor(appointment.kind, l10n),
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
      width: 58,
      height: 38,
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
