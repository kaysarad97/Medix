import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
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
    // Своим отзывом подписывается имя из профиля.
    final profile = ref.watch(profileProvider).value;
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
                  // Активна только после выбора дня и времени. Настоящего
                  // бронирования нет — заглушка `DoctorsRepository.appointment`
                  // игнорирует id и всегда отдаёт один и тот же мок-приём,
                  // тот же, что и в «Предстоящих записях» на главной.
                  onTap: selected?.slot == null
                      ? null
                      : () => context.push(Routes.appointmentOf('a1')),
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
              // Пока профиль не загрузился, отзыв нечем подписать —
              // отправка молчит, а печатать уже можно.
              onSubmit: profile == null
                  ? null
                  : (text) => ref
                        .read(composedReviewsProvider.notifier)
                        .add(text: text, authorName: profile.fullName),
            ),
          ),
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
