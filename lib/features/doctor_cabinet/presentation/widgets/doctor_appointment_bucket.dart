import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import 'doctor_calendar_metrics.dart';

/// Одна корзина календаря — «Утренние/Дневные/Вечерние записи»: заголовок
/// и пронумерованные строки записей, либо плашка «Записей пока нет».
class DoctorAppointmentBucket extends StatelessWidget {
  const DoctorAppointmentBucket({
    super.key,
    required this.title,
    required this.appointments,
  });

  final String title;
  final List<DoctorAppointment> appointments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: DoctorCalendarMetrics.bucketHeaderHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppTypography.sectionTitle),
          ),
        ),
        if (appointments.isEmpty)
          const _EmptyRow()
        else
          for (final (index, appointment) in appointments.indexed) ...[
            if (index > 0) const SizedBox(height: DoctorCalendarMetrics.rowGap),
            _Row(number: index + 1, appointment: appointment),
          ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.number, required this.appointment});

  final int number;
  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorCalendarMetrics.rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text('$number', style: AppTypography.cardItemMeta),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppRadius.allMd,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  children: [
                    UserAvatar(
                      asset: appointment.patientAvatarAsset,
                      size: const Size.square(36),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appointment.patientName,
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _TimePill(text: appointment.timeLabel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.text});

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

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: DoctorCalendarMetrics.rowHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
        ),
        child: Center(
          child: Text(
            l10n.doctorCalendarEmptyLabel,
            style: AppTypography.tileSubtitle,
          ),
        ),
      ),
    );
  }
}
