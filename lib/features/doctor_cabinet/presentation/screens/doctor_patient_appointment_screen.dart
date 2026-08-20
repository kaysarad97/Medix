import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_button_row.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_conclusion_card.dart';
import '../widgets/doctor_history_row.dart';
import '../widgets/doctor_patient_header.dart';
import '../widgets/doctor_patient_metrics.dart';

/// «Запись с пациентом» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Запись с пациентом.png`
/// (440×978; плавающий таб-бар внизу макета — артефакт коллажа).
///
/// Врач от клиники запись не отменяет и не подтверждает сам — для этого у
/// него «Запросы к админу»; у фрилансера на этом же экране появятся кнопки
/// подтверждения, но это следующий слайс.
class DoctorPatientAppointmentScreen extends ConsumerWidget {
  const DoctorPatientAppointmentScreen({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final patient = ref.watch(doctorPatientProvider(patientId)).value;
    final appointment = patient?.appointment;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: patient == null || appointment == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DoctorPatientMetrics.topBarTop),
                    ScreenTopBar(
                      title: l10n.doctorAppointmentTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: DoctorPatientMetrics.topBarToHeader),
                    _Section(child: DoctorPatientHeader(patient: patient)),
                    const SizedBox(
                      height: DoctorPatientMetrics.headerToSummaryRow,
                    ),
                    _Section(child: _SummaryRow(appointment: appointment)),
                    const SizedBox(
                      height: DoctorPatientMetrics.summaryToActions,
                    ),
                    _Section(
                      child: ActionButtonRow(
                        height: DoctorPatientMetrics.actionHeight,
                        // Кнопки равной ширины — 193 и 193 по макету.
                        primaryFlex: 1,
                        secondaryFlex: 1,
                        primary: ActionButtonData(
                          icon: MedixIcon.audioCall,
                          title: l10n.startCallTitle,
                          subtitle: DoctorHistoryRow.kindLabel(
                            appointment.kind,
                            l10n,
                          ),
                          // Звонок со стороны врача пока некуда вести:
                          // экран звонка живёт в пациентской фиче и завязан
                          // на её запись.
                        ),
                        secondary: ActionButtonData(
                          icon: MedixIcon.mail,
                          title: l10n.doctorWritePatientTitle,
                          subtitle: l10n.doctorPatientChatSubtitle,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: DoctorPatientMetrics.actionsToConclusion,
                    ),
                    _Section(
                      child: DoctorConclusionCard(
                        patientName: patient.fullName,
                        date: appointment.startsAt,
                        conclusion: patient.conclusion,
                      ),
                    ),
                    SizedBox(
                      height:
                          DoctorPatientMetrics.screenH +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Белая строка с видом записи и её временем.
///
/// Отличается от строки «Истории записей» только подписью: там имя
/// пациента, здесь «Ваша запись» — пациент уже показан в шапке.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: DoctorPatientMetrics.summaryRowHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              const AppIconChip(
                icon: MedixIcon.mail,
                size: 32,
                background: AppColors.accentSofter,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DoctorHistoryRow.kindLabel(appointment.kind, l10n),
                      style: AppTypography.cardItemTitle,
                    ),
                    Text(
                      l10n.doctorOwnAppointmentSubtitle,
                      style: AppTypography.linkSmall,
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
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorPatientMetrics.screenH,
      ),
      child: child,
    );
  }
}
