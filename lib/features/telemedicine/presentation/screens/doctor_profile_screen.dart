import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/action_button_row.dart';
import '../widgets/city_chip.dart';
import '../widgets/doctor_header.dart';
import '../widgets/doctor_metrics.dart';
import '../widgets/reviews_card.dart';
import '../widgets/schedule_card.dart';

/// Профиль врача с записью на приём.
///
/// Свёрстан по `design/Профиль врача + запись.png` (440×1010 — страница
/// прокручиваемая).
class DoctorProfileScreen extends ConsumerWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(doctorProvider(doctorId));
    final schedule = ref.watch(doctorScheduleProvider(doctorId));
    final reviews = ref.watch(doctorReviewsProvider(doctorId));

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: doctor.value == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                doctor: doctor.value!,
                schedule: schedule.value,
                reviews: reviews.value ?? const [],
              ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({
    required this.doctor,
    required this.schedule,
    required this.reviews,
  });

  final Doctor doctor;
  final DoctorSchedule? schedule;
  final List<DoctorReview> reviews;

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
            title: 'О враче',
            onBack: () => Navigator.of(context).maybePop(),
            trailing: doctor.city == null ? null : CityChip(city: doctor.city!),
          ),
          const SizedBox(height: DoctorMetrics.topBarToHeader),
          DoctorHeader(doctor: doctor),
          const SizedBox(height: DoctorMetrics.photoToCard),
          if (schedule != null)
            _Section(
              child: ScheduleCard(
                title: 'Расписание',
                schedule: schedule!,
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
          const SizedBox(height: DoctorMetrics.cardGap),
          if (reviews.isNotEmpty)
            _Section(child: ReviewsCard(reviews: reviews)),
          const SizedBox(height: DoctorMetrics.composerTop),
          const _Section(child: ReviewComposer()),
          const SizedBox(height: DoctorMetrics.screenH),
        ],
      ),
    );
  }
}

/// Горизонтальные поля карточек.
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
