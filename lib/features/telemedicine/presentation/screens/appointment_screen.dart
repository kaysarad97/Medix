import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_schedule.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/action_button_row.dart';
import '../widgets/appointment_summary_card.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_metrics.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(scheduleSelectionProvider.notifier);
    final selected = schedule == null
        ? null
        : ref.watch(scheduleSelectionProvider).resolve(schedule!);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DoctorMetrics.topBarTop),
          ScreenTopBar(
            title: 'Ваша запись',
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
                title: 'Начать звонок',
                subtitle: appointment.kind.label,
                onTap: () {},
              ),
              secondary: ActionButtonData(
                icon: MedixIcon.chat,
                title: 'Сообщение',
                subtitle: 'Чат с врачом',
                onTap: () => context.push(Routes.chats),
              ),
            ),
          ),
          const SizedBox(height: DoctorMetrics.actionsToReschedule),
          if (schedule != null)
            _Section(
              child: ScheduleCard(
                title: 'Перенести запись',
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
                  title: 'Создать запись',
                  subtitle: 'Видео-звонок',
                  onTap: () {},
                ),
                secondaryAction: ActionButtonData(
                  icon: MedixIcon.mail,
                  title: 'Сообщение',
                  subtitle: 'Чат с врачом',
                  onTap: () => context.push(Routes.chats),
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
