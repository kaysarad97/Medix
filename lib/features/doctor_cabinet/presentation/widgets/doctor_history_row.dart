import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor_appointment.dart';
import 'doctor_history_metrics.dart';

/// Строка прошедшей записи — «История записей.png»: кружок вида записи,
/// «Аудио-звонок» с подписью «с Имя Фамилия» и время справа.
///
/// Одна и та же строка стоит и в выделенной карточке «Предыдущая запись»,
/// и в списке «Другие записи» — отличий в макете нет, кроме подложки под
/// карточкой.
class DoctorHistoryRow extends StatelessWidget {
  const DoctorHistoryRow({super.key, required this.appointment, this.onTap});

  final DoctorAppointment appointment;
  final VoidCallback? onTap;

  /// Подпись вида записи. Собирается здесь, а не в модели: у `enum` нет
  /// доступа к `BuildContext` — то же правило, что и в остальном коде.
  static String kindLabel(AppointmentKind kind, AppLocalizations l10n) =>
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
      height: DoctorHistoryMetrics.rowHeight,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DoctorHistoryMetrics.cardPadding,
            ),
            child: Row(
              children: [
                const AppIconChip(
                  icon: MedixIcon.mail,
                  size: DoctorHistoryMetrics.rowIconSize,
                  // Кружок в макетах врача светлее, чем по умолчанию у
                  // AppIconChip: пипетка даёт C0DDFF, а не 9CCAFF.
                  background: AppColors.accentSofter,
                ),
                const SizedBox(width: DoctorHistoryMetrics.rowIconGap),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kindLabel(appointment.kind, l10n),
                        style: AppTypography.cardItemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        l10n.doctorHistoryWithPatient(appointment.patientName),
                        style: AppTypography.linkSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  appointment.historyLabel,
                  style: AppTypography.cardItemTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
