import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
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
                    _Section(child: _PatientRow(appointment: appointment)),
                    const SizedBox(
                      height: DoctorHistoryMetrics.patientRowToConclusion,
                    ),
                    _Section(child: _ConclusionCard(appointment: appointment)),
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
///
/// Вести пока некуда: «Профиль пациента» — отдельный макет, он в следующем
/// слайсе кабинета. Строка нажимается, но обработчика у неё нет — как
/// плитки на главной до этого захода.
class _PatientRow extends StatelessWidget {
  const _PatientRow({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: DoctorHistoryMetrics.patientRowHeight,
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
    );
  }
}

/// Заключение врача о приёме либо объяснение, почему его ещё нет.
class _ConclusionCard extends StatelessWidget {
  const _ConclusionCard({required this.appointment});

  final DoctorAppointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: AppColors.accentSoft,
      padding: const EdgeInsets.all(DoctorHistoryMetrics.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height:
                DoctorHistoryMetrics.conclusionHeaderHeight -
                DoctorHistoryMetrics.cardPadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.doctorPastConclusionTitle(appointment.patientName),
                    style: AppTypography.cardItemTitle,
                  ),
                ),
                Text(
                  l10n.doctorPastConclusionDate(
                    RuDates.dayMonthShortYear(appointment.startsAt),
                  ),
                  style: AppTypography.cardItemMeta,
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                appointment.conclusion ?? l10n.doctorPastConclusionPlaceholder,
                style: appointment.conclusion == null
                    ? AppTypography.placeholder
                    : AppTypography.bodyMd,
              ),
            ),
          ),
          const SizedBox(height: DoctorHistoryMetrics.conclusionBodyToUpload),
          SizedBox(
            height: DoctorHistoryMetrics.uploadRowHeight,
            child: Material(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                // Загружать пока некуда: файлового хранилища у кабинета
                // врача нет, как и самого бэкенда под него.
                onTap: null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.doctorPastUploadConclusion,
                      style: AppTypography.linkSmall,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
