import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/ru_dates.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_schedule.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/action_button_row.dart';
import '../widgets/appointment_summary_card.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_metrics.dart';
import '../widgets/prepayment_card.dart';
import '../widgets/schedule_card.dart';

/// Оформленная запись: как связаться с врачом и как перенести приём.
///
/// Свёрстан по `design/Ваша Запись.png` (440×978).
class AppointmentScreen extends ConsumerWidget {
  const AppointmentScreen({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointment = ref.watch(appointmentProvider(appointmentId));
    final doctorId = appointment.value?.doctorId;

    final doctor = doctorId == null
        ? null
        : ref.watch(doctorProvider(doctorId)).value;
    final schedule = doctorId == null
        ? null
        : ref.watch(doctorScheduleProvider(doctorId)).value;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: appointment.value == null || doctor == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                appointment: appointment.value!,
                doctor: doctor,
                schedule: schedule,
              ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.appointment,
    required this.doctor,
    required this.schedule,
  });

  final Appointment appointment;
  final Doctor doctor;
  final DoctorSchedule? schedule;

  static String _labelFor(AppointmentKind kind, AppLocalizations l10n) =>
      switch (kind) {
        AppointmentKind.videoCall => l10n.videoCallSubtitle,
        AppointmentKind.audioCall => l10n.audioCallLabel,
        AppointmentKind.chat => l10n.chatAppointmentLabel,
        AppointmentKind.inPerson => l10n.inPersonAppointmentLabel,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(scheduleSelectionProvider.notifier);
    final selected = schedule == null
        ? null
        : ref.watch(scheduleSelectionProvider).resolve(schedule!);
    // Скидку на конкретную запись считает сервер, и её может не быть даже у
    // подписчика — тариф даёт её не на всё. Тариф нужен здесь только затем,
    // чтобы не предлагать оформить подписку тому, кто её уже оформил.
    final subscription = ref.watch(profileProvider).value?.subscription;
    final hasSubscription =
        subscription != null && subscription != SubscriptionTier.free;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DoctorMetrics.topBarTop),
          ScreenTopBar(
            title: l10n.appointmentTitle,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: DoctorMetrics.topBarToHeader),
          DoctorHeader(doctor: doctor),
          const SizedBox(height: DoctorMetrics.photoToSummary),
          _Section(child: AppointmentSummaryCard(appointment: appointment)),
          const SizedBox(height: DoctorMetrics.summaryToActions),
          _Section(
            child: ActionButtonRow(
              height: DoctorMetrics.callActionHeight,
              // На этом экране кнопки равной ширины, в отличие от карточки
              // расписания.
              primaryFlex: 1,
              secondaryFlex: 1,
              primary: ActionButtonData(
                icon: MedixIcon.audioCall,
                title: l10n.startCallTitle,
                subtitle: _labelFor(appointment.kind, l10n),
                onTap: () => context.push(Routes.callOf(appointment.id)),
              ),
              secondary: ActionButtonData(
                icon: MedixIcon.chat,
                title: l10n.messageActionTitle,
                subtitle: l10n.doctorChatTitle,
                onTap: () => context.push(Routes.chatOf('t1')),
              ),
            ),
          ),
          if (appointment.basePriceLabel != null) ...[
            const SizedBox(height: DoctorMetrics.summaryToActions),
            _Section(
              child: PrepaymentCard(
                appointment: appointment,
                hasSubscription: hasSubscription,
                // Kaspi и Apple Pay проводят оплату своим интерфейсом — SDK
                // ещё нет, поэтому оба ведут в один и тот же мок-результат,
                // как кнопки на PaymentMethodScreen.
                onPay: (method) =>
                    context.push(Routes.paymentResultOf('success')),
                onSubscribe: () => context.push(Routes.subscription),
              ),
            ),
          ],
          const SizedBox(height: DoctorMetrics.actionsToReschedule),
          if (schedule != null)
            _Section(
              child: ScheduleCard(
                title: l10n.rescheduleTitle,
                schedule: schedule!,
                // Стрелок перелистывания месяца на этом макете нет.
                showMonthArrows: false,
                selectedDay: selected?.day,
                selectedSlot: selected?.slot,
                onDaySelected: notifier.selectDay,
                onSlotSelected: notifier.selectSlot,
                primaryAction: ActionButtonData(
                  // В макете здесь трубка, а не камера, хотя подпись
                  // «Видео-звонок» — так на обоих экранах.
                  icon: MedixIcon.audioCall,
                  title: l10n.createAppointmentTitle,
                  subtitle: l10n.videoCallSubtitle,
                  // Активна только после выбора нового дня и времени.
                  // Бэкенда нет — переносом считаем показ подтверждения,
                  // изменить дату самого приёма нечем: `appointment(id)`
                  // в заглушке не принимает новое время.
                  onTap: selected?.slot == null
                      ? null
                      : () {
                          final slot = selected!.slot!;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.appointmentRescheduledSnackbar(
                                    RuDates.dayMonth(slot.startsAt),
                                    slot.timeLabel,
                                  ),
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          Navigator.of(context).maybePop();
                        },
                ),
                secondaryAction: ActionButtonData(
                  icon: MedixIcon.mail,
                  title: l10n.messageActionTitle,
                  subtitle: l10n.doctorChatTitle,
                  onTap: () => context.push(Routes.chatOf('t1')),
                ),
              ),
            ),
          const SizedBox(height: DoctorMetrics.screenH),
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
      padding: const EdgeInsets.symmetric(horizontal: DoctorMetrics.screenH),
      child: child,
    );
  }
}
