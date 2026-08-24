import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_conclusion_card.dart';
import '../widgets/doctor_conclusion_dialog.dart';
import '../widgets/doctor_history_metrics.dart';
import '../widgets/doctor_history_row.dart';

/// «О прошлой записи» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/О прошлой записи.png`
/// (440×956). Заголовок экрана в макете тот же, что у списка, — «История
/// записей», это не опечатка.
class DoctorPastAppointmentScreen extends ConsumerWidget {
  const DoctorPastAppointmentScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final appointment = ref
        .watch(doctorPastAppointmentProvider(appointmentId))
        .value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: appointment == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DoctorHistoryMetrics.topBarTop),
                    ScreenTopBar(
                      title: l10n.doctorHistoryTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: DoctorHistoryMetrics.topBarToCard),
                    _Section(child: _SummaryCard(appointment: appointment)),
                    const SizedBox(
                      height: DoctorHistoryMetrics.summaryToPatientRow,
                    ),
                    _Section(
                      child: _PatientRow(
                        appointment: appointment,
                        // Пациент в заглушке один, и его идентификатор
                        // совпадает с идентификатором записи.
                        onTap: () => context.push(
                          Routes.doctorPatientOf(appointment.id),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: DoctorHistoryMetrics.patientRowToConclusion,
                    ),
                    _Section(
                      child: DoctorConclusionCard(
                        patientName: appointment.patientName,
                        date: appointment.startsAt,
                        conclusion: appointment.conclusion,
                        // На этом макете у строки загрузки шеврона нет, в
                        // отличие от «Профиля пациента».
                        showUploadChevron: false,
                        onUpload: () =>
                            _saveConclusion(context, ref, appointment),
                      ),
                    ),
                    SizedBox(
                      height:
                          DoctorHistoryMetrics.screenH +
                          MediaQuery.paddingOf(context).bottom,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _saveConclusion(
    BuildContext context,
    WidgetRef ref,
    DoctorAppointment appointment,
  ) async {
    final text = await showDoctorConclusionDialog(
      context,
      initialText: appointment.conclusion,
    );
    if (text == null || !context.mounted) return;

    try {
      await ref
          .read(doctorCabinetRepositoryProvider)
          .saveConclusion(appointment.id, text);
      ref.invalidate(doctorPastAppointmentProvider(appointment.id));
      ref.invalidate(doctorPastAppointmentsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.doctorConclusionSaved),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showFormErrorSnackBar(
        context,
        AppLocalizations.of(context)!.doctorConclusionSaveError,
      );
    }
  }
}

/// Вид записи, пациент и время — верхняя карточка.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: SizedBox(
        height: DoctorHistoryMetrics.pastSummaryHeight - 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DoctorHistoryRow.kindLabel(appointment.kind, l10n),
                    style: AppTypography.sectionTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.doctorPastWithPatient(appointment.patientName),
                    style: AppTypography.cardTitleAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              // Без конца приёма: на карточке подписано только начало.
              '${appointment.shortDate}, ${RuDates.hourMinute(appointment.startsAt)}',
              style: AppTypography.cardTitleAccent,
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка перехода в профиль пациента.
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.appointment, this.onTap});

  final DoctorAppointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.surfaceWhite,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: DoctorHistoryMetrics.patientRowHeight,
        child: Material(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  UserAvatar(
                    asset: appointment.patientAvatarAsset,
                    size: const Size.square(44),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.patientName,
                          style: AppTypography.cardTitleAccent,
                        ),
                        Text(
                          l10n.doctorPastPatientProfileLabel,
                          style: AppTypography.tileSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.primaryBright,
                  ),
                ],
              ),
            ),
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
        horizontal: DoctorHistoryMetrics.screenH,
      ),
      child: child,
    );
  }
}
