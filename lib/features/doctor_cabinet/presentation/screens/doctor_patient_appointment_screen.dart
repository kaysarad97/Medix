import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/platform/external_url_opener.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_button_row.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_appointment_files_card.dart';
import '../widgets/doctor_cancel_appointment_dialog.dart';
import '../widgets/doctor_conclusion_card.dart';
import '../widgets/doctor_history_row.dart';
import '../widgets/doctor_no_show_dialog.dart';
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
class DoctorPatientAppointmentScreen extends ConsumerStatefulWidget {
  const DoctorPatientAppointmentScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<DoctorPatientAppointmentScreen> createState() =>
      _DoctorPatientAppointmentScreenState();
}

class _DoctorPatientAppointmentScreenState
    extends ConsumerState<DoctorPatientAppointmentScreen> {
  DoctorAppointment? _updatedAppointment;
  bool _cancelling = false;
  bool _markingNoShow = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final patient = ref.watch(doctorPatientProvider(widget.patientId)).value;
    final appointment = _updatedAppointment ?? patient?.appointment;
    final profile = ref.watch(doctorOwnProfileProvider).value;
    final isInPerson = appointment?.kind == AppointmentKind.inPerson;
    final canCancel =
        profile?.isFreelancer == true &&
        (appointment?.status == AppointmentStatus.pending ||
            appointment?.status == AppointmentStatus.confirmed);
    // Не привязано к роли, в отличие от canCancel: интерфейс репозитория
    // (`markAppointmentNoShow`) не разделяет фрилансера и врача от
    // клиники — неявка это факт, а не решение, которое нужно согласовать
    // с администрацией. Доступно только после времени начала приёма
    // (см. doc-комментарий у `markAppointmentNoShow` в
    // `doctor_cabinet_repository.dart`) и только пока запись ещё
    // подтверждена — иначе уже отменена/завершена/отмечена.
    final canMarkNoShow =
        appointment?.status == AppointmentStatus.confirmed &&
        appointment != null &&
        DateTime.now().isAfter(appointment.startsAt);

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
                          title: isInPerson
                              ? l10n.doctorCallPatientTitle
                              : l10n.startCallTitle,
                          subtitle: DoctorHistoryRow.kindLabel(
                            appointment.kind,
                            l10n,
                          ),
                          onTap: isInPerson
                              ? () => _callPatient(
                                  context,
                                  ref,
                                  appointment.patientPhone,
                                )
                              : () => context.push(
                                  Routes.doctorCallOf(widget.patientId),
                                ),
                        ),
                        secondary: ActionButtonData(
                          icon: MedixIcon.mail,
                          title: l10n.doctorWritePatientTitle,
                          subtitle: l10n.doctorPatientChatSubtitle,
                          onTap: () => _openPatientChat(
                            context,
                            appointment.consultationId,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: DoctorPatientMetrics.actionsToConclusion,
                    ),
                    if (canCancel) ...[
                      Text(
                        l10n.doctorCancelAppointmentAlternative,
                        textAlign: TextAlign.center,
                        style: AppTypography.cardItemMeta,
                      ),
                      const SizedBox(height: 10),
                      _Section(
                        child: _CancelAppointmentButton(
                          loading: _cancelling,
                          onTap: _cancelling
                              ? null
                              : () => _cancelAppointment(appointment),
                        ),
                      ),
                      const SizedBox(
                        height: DoctorPatientMetrics.actionsToConclusion,
                      ),
                    ],
                    if (canMarkNoShow) ...[
                      _Section(
                        child: _NoShowButton(
                          loading: _markingNoShow,
                          onTap: _markingNoShow
                              ? null
                              : () => _markNoShow(appointment),
                        ),
                      ),
                      const SizedBox(
                        height: DoctorPatientMetrics.actionsToConclusion,
                      ),
                    ],
                    if (appointment.files.isNotEmpty) ...[
                      _Section(
                        child: DoctorAppointmentFilesCard(
                          files: appointment.files,
                        ),
                      ),
                      const SizedBox(height: DoctorPatientMetrics.cardGap),
                    ],
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

  Future<void> _cancelAppointment(DoctorAppointment appointment) async {
    final reason = await showDoctorCancelAppointmentDialog(context);
    if (reason == null || !mounted) return;

    setState(() => _cancelling = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final updated = await ref
          .read(doctorCabinetRepositoryProvider)
          .cancelAppointment(appointment.id, reason);
      if (!mounted) return;
      setState(() {
        _updatedAppointment = updated;
        _cancelling = false;
      });
      ref.invalidate(doctorUpcomingAppointmentsProvider);
      ref.invalidate(doctorAppointmentsForDayProvider);
      ref.invalidate(doctorRegularPatientsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.doctorCancelAppointmentSuccess)),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _cancelling = false);
      showFormErrorSnackBar(context, l10n.doctorCancelAppointmentError);
    }
  }

  Future<void> _markNoShow(DoctorAppointment appointment) async {
    final confirmed = await showDoctorNoShowDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _markingNoShow = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      // В отличие от cancelAppointment, эндпоинт `PATCH .../no-show` не
      // возвращает обновлённую запись (см. doc-комментарий у
      // `markAppointmentNoShow` в `doctor_cabinet_repository.dart`) —
      // обновляем локально через уже готовый `copyWithStatus`, который
      // раньше нигде не вызывался.
      await ref
          .read(doctorCabinetRepositoryProvider)
          .markAppointmentNoShow(appointment.id);
      if (!mounted) return;
      setState(() {
        _updatedAppointment = appointment.copyWithStatus(
          AppointmentStatus.noShow,
        );
        _markingNoShow = false;
      });
      ref.invalidate(doctorUpcomingAppointmentsProvider);
      ref.invalidate(doctorAppointmentsForDayProvider);
      ref.invalidate(doctorRegularPatientsProvider);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.doctorNoShowSuccess)));
    } on Object {
      if (!mounted) return;
      setState(() => _markingNoShow = false);
      showFormErrorSnackBar(context, l10n.doctorNoShowError);
    }
  }
}

class _CancelAppointmentButton extends StatelessWidget {
  const _CancelAppointmentButton({required this.loading, this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 49,
      child: Material(
        color: AppColors.accentSofter,
        borderRadius: ActionButtonRow.radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('doctor-cancel-appointment'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: loading
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: AppColors.primaryBright,
                        ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.doctorCancelAppointmentAction,
                  style: AppTypography.actionTitle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Тот же вид, что у `_CancelAppointmentButton` — разный только текст,
/// иконка и `ValueKey` для тестов.
class _NoShowButton extends StatelessWidget {
  const _NoShowButton({required this.loading, this.onTap});

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 49,
      child: Material(
        color: AppColors.accentSofter,
        borderRadius: ActionButtonRow.radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('doctor-mark-no-show'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: loading
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.person_off_outlined,
                          size: 17,
                          color: AppColors.primaryBright,
                        ),
                ),
                const SizedBox(width: 10),
                Text(l10n.doctorNoShowAction, style: AppTypography.actionTitle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _callPatient(
  BuildContext context,
  WidgetRef ref,
  String? patientPhone,
) async {
  final phone = patientPhone?.trim();
  if (phone == null || phone.isEmpty) {
    showFormErrorSnackBar(
      context,
      AppLocalizations.of(context)!.doctorPatientPhoneUnavailable,
    );
    return;
  }

  try {
    final opened = await ref.read(externalUrlOpenerProvider)(
      Uri(scheme: 'tel', path: phone),
    );
    if (!opened && context.mounted) {
      showFormErrorSnackBar(
        context,
        AppLocalizations.of(context)!.doctorPatientPhoneOpenError,
      );
    }
  } on Object {
    if (context.mounted) {
      showFormErrorSnackBar(
        context,
        AppLocalizations.of(context)!.doctorPatientPhoneOpenError,
      );
    }
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
