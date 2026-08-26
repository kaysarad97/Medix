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
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../profile/presentation/widgets/analyses_card.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_appointment_files_card.dart';
import '../widgets/doctor_conclusion_card.dart';
import '../widgets/doctor_patient_header.dart';
import '../widgets/doctor_patient_metrics.dart';

/// «Профиль пациента» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Профиль пациента.png`
/// (440×1438 — страница прокручиваемая; плавающий таб-бар в середине
/// макета не второй блок, а артефакт коллажа, как и на «Ваш Профиль»).
///
/// Карточка анализов взята пациентская (`AnalysesCard` из `profile`) — та
/// же строка со шкалой и тем же переключателем вкладок; второй такой
/// заводить незачем. Из другой фичи её уже импортирует «Моя Семья».
class DoctorPatientScreen extends ConsumerWidget {
  const DoctorPatientScreen({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final patient = ref.watch(doctorPatientProvider(patientId)).value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: patient == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: DoctorPatientMetrics.topBarTop),
                    ScreenTopBar(
                      title: l10n.doctorPatientTitle,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: DoctorPatientMetrics.topBarToHeader),
                    _Section(child: DoctorPatientHeader(patient: patient)),
                    const SizedBox(height: DoctorPatientMetrics.headerToCard),
                    if (patient.appointment case final appointment?) ...[
                      _Section(child: _ConfirmCard(appointment: appointment)),
                      const SizedBox(height: DoctorPatientMetrics.cardGap),
                      if (appointment.files.isNotEmpty) ...[
                        _Section(
                          child: DoctorAppointmentFilesCard(
                            files: appointment.files,
                          ),
                        ),
                        const SizedBox(height: DoctorPatientMetrics.cardGap),
                      ],
                    ],
                    _Section(
                      child: DoctorConclusionCard(
                        patientName: patient.fullName,
                        date: patient.appointment?.startsAt ?? DateTime.now(),
                        conclusion: patient.conclusion,
                      ),
                    ),
                    const SizedBox(height: DoctorPatientMetrics.cardGap),
                    _Section(
                      child: AnalysesCard(
                        analyses: patient.analyses,
                        filter: AnalysesFilter.changed,
                        title: l10n.doctorPatientAnalysesTitle,
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

/// «Подтвердите запись»: дата с временем и строка перехода в переписку.
class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(DoctorPatientMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Заголовок отступлен внутрь сильнее строки: в макете он на x 40
          // при поле карточки 34.
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(
              l10n.doctorConfirmAppointmentTitle,
              style: AppTypography.cardTitleAccent,
            ),
          ),
          const SizedBox(height: DoctorPatientMetrics.confirmTitleToDate),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.doctorAppointmentDateAt(
                      RuDates.dayMonthWeekday(appointment.startsAt),
                    ),
                    style: AppTypography.sectionTitle,
                  ),
                ),
                const SizedBox(width: 8),
                _TimePill(text: appointment.timeLabel),
              ],
            ),
          ),
          const SizedBox(height: DoctorPatientMetrics.dateToMessageRow),
          _MessageRow(
            title: l10n.doctorWritePatientTitle,
            subtitle: l10n.doctorWritePatientSubtitle,
            onTap: () => _openPatientChat(context, appointment.consultationId),
          ),
        ],
      ),
    );
  }
}

void _openPatientChat(BuildContext context, String? consultationId) {
  if (consultationId == null) {
    showFormErrorSnackBar(
      context,
      AppLocalizations.of(context)!.doctorPatientChatUnavailable,
    );
    return;
  }
  context.push(Routes.doctorPatientChatOf(consultationId));
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DoctorPatientMetrics.timePillWidth,
      height: DoctorPatientMetrics.timePillHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accentSofter,
          borderRadius: AppRadius.allMd,
        ),
        child: Center(
          // РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ: в макете время набрано
          // курсивом, а у Golos Text курсивного начертания нет — то же
          // ограничение, что и с именем в пациентском профиле.
          child: Text(text, style: AppTypography.cardTitleAccent),
        ),
      ),
    );
  }
}

/// Белая строка «Сообщение / Написать пациенту».
class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorPatientMetrics.rowHeight,
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
                      Text(title, style: AppTypography.cardItemTitle),
                      Text(subtitle, style: AppTypography.linkSmall),
                    ],
                  ),
                ),
              ],
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
        horizontal: DoctorPatientMetrics.screenH,
      ),
      child: child,
    );
  }
}
