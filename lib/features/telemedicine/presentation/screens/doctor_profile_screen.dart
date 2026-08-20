import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/appointment.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';
import '../providers/telemedicine_providers.dart';
import '../../../../core/widgets/action_button_row.dart';
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
    // Написанное здесь же идёт первым: свой отзыв должно быть видно сразу.
    final composed = ref.watch(composedReviewsProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: doctor.value == null
            ? const Center(child: CircularProgressIndicator())
            : _Content(
                doctor: doctor.value!,
                schedule: schedule.value,
                reviews: [...composed, ...?reviews.value],
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
    final weekOffset = ref.watch(scheduleWeekOffsetProvider);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: DoctorMetrics.topBarTop),
          ScreenTopBar(
            title: l10n.aboutDoctorTitle,
            onBack: () => Navigator.of(context).maybePop(),
            trailing: doctor.city == null ? null : CityChip(city: doctor.city!),
          ),
          const SizedBox(height: DoctorMetrics.topBarToHeader),
          DoctorHeader(doctor: doctor),
          const SizedBox(height: DoctorMetrics.photoToCard),
          if (schedule != null)
            _Section(
              child: ScheduleCard(
                title: l10n.scheduleTitle,
                schedule: schedule!,
                // Листание недель. Назад с текущей нельзя — записаться в
                // прошлое некуда, и стрелка на нуле гаснет. Выбор дня при
                // листании сбрасывается: он остался в прошлой ленте.
                onPreviousMonth: weekOffset == 0
                    ? null
                    : () {
                        ref
                            .read(scheduleWeekOffsetProvider.notifier)
                            .previous();
                        notifier.reset();
                      },
                onNextMonth: () {
                  ref.read(scheduleWeekOffsetProvider.notifier).next();
                  notifier.reset();
                },
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
                  // Активна только после выбора дня и времени.
                  onTap: selected?.slot == null
                      ? null
                      : () => _book(context, ref, doctor, selected!.slot!),
                ),
                secondaryAction: ActionButtonData(
                  icon: MedixIcon.mail,
                  title: l10n.messageActionTitle,
                  subtitle: l10n.doctorChatTitle,
                  // В переписку с врачом, а не в список чатов: список —
                  // ветка нижней навигации, и `push` на неё поднимает вторую
                  // копию оболочки с теми же глобальными ключами. Навигатор
                  // на этом падает.
                  //
                  // Связи «врач → переписка» в заглушке нет, поэтому id
                  // временный — как и мок-приём в кнопке рядом.
                  onTap: () => context.push(Routes.chatOf('t1')),
                ),
              ),
            ),
          const SizedBox(height: DoctorMetrics.cardGap),
          if (reviews.isNotEmpty)
            _Section(child: ReviewsCard(reviews: reviews)),
          const SizedBox(height: DoctorMetrics.composerTop),
          _Section(
            child: ReviewComposer(
              onTap: () => context.push(Routes.doctorReviewOf(doctor.id)),
            ),
          ),
          const SizedBox(height: DoctorMetrics.screenH),
        ],
      ),
    );
  }
}

/// Оформляет запись на выбранный слот и открывает её.
///
/// Формат — видео-звонок: так подписана кнопка в макете. Сервер знает ещё
/// аудио и очный приём, но выбирать формат на этом экране негде.
Future<void> _book(
  BuildContext context,
  WidgetRef ref,
  Doctor doctor,
  ScheduleSlot slot,
) async {
  try {
    final appointment = await ref
        .read(doctorsRepositoryProvider)
        .book(doctor: doctor, slot: slot, kind: AppointmentKind.videoCall);
    if (context.mounted) {
      context.push(Routes.appointmentOf(appointment.id));
    }
  } on ApiException catch (e) {
    // Слот мог занять кто-то другой между чтением расписания и нажатием —
    // сервер отвечает 409, и это единственный способ о нём узнать.
    if (context.mounted) showFormErrorSnackBar(context, e.message);
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
