import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../data/repositories/consultation_socket.dart';
import '../../data/repositories/consultations_repository.dart';
import '../../data/repositories/doctors_repository.dart';
import '../../data/repositories/remote_doctors_repository.dart';
import '../../domain/entities/consultation.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  if (useMocks) return const MockDoctorsRepository();

  return RemoteDoctorsRepository(ref.watch(dioClientProvider));
});

final consultationsRepositoryProvider = Provider<ConsultationsRepository>(
  (ref) => ConsultationsRepository(ref.watch(dioClientProvider)),
);

final consultationMessagesProvider = FutureProvider.autoDispose
    .family<List<ConsultationMessage>, String>(
      (ref, consultationId) =>
          ref.watch(consultationsRepositoryProvider).messages(consultationId),
    );

final consultationSocketProvider = Provider.autoDispose
    .family<ConsultationSocket, String>((ref, _) {
      final socket = ConsultationSocket();
      ref.onDispose(socket.close);
      return socket;
    });

final doctorProvider = FutureProvider.autoDispose.family<Doctor, String>(
  (ref, id) => ref.watch(doctorsRepositoryProvider).doctor(id),
);

/// Специальности для грида «Все Врачи» на экране поиска.
final doctorSpecialtiesProvider = FutureProvider<List<DoctorSpecialty>>(
  (ref) => ref.watch(doctorsRepositoryProvider).specialties(),
);

/// «Мои Врачи» на том же экране.
final myDoctorsProvider = FutureProvider<List<MyDoctor>>(
  (ref) => ref.watch(doctorsRepositoryProvider).myDoctors(),
);

/// Результаты поиска по специальности/запросу.
final doctorSearchResultsProvider = FutureProvider.autoDispose
    .family<List<Doctor>, String>(
      (ref, query) => ref.watch(doctorsRepositoryProvider).search(query),
    );

/// На сколько недель вперёд отлистана лента расписания. Ноль — текущая.
///
/// Назад не уходим: записаться в прошлое нельзя, и стрелка «влево» на нуле
/// гаснет.
class ScheduleWeekOffset extends Notifier<int> {
  @override
  int build() => 0;

  void next() => state = state + 1;

  void previous() {
    if (state > 0) state = state - 1;
  }
}

final scheduleWeekOffsetProvider = NotifierProvider<ScheduleWeekOffset, int>(
  ScheduleWeekOffset.new,
);

/// Расписание перечитывается при каждом открытии экрана врача.
///
/// `autoDispose` — не оптимизация памяти, а исправление: без него лента
/// слотов читалась один раз за запуск, и занятые кем-то (или, наоборот,
/// открытые врачом) слоты обновлялись только после перезапуска приложения.
/// Поймано на живом API.
final doctorScheduleProvider = FutureProvider.autoDispose
    .family<DoctorSchedule, String>((ref, doctorId) {
      final weeks = ref.watch(scheduleWeekOffsetProvider);
      final now = DateTime.now();

      // На текущей неделе отсчёт от «сейчас», чтобы отпало уже прошедшее время.
      // На будущих — от начала дня: там отсекать нечего, а от времени суток
      // набор часов зависеть не должен.
      final from = weeks == 0
          ? now
          : DateTime(now.year, now.month, now.day + weeks * 7);

      return ref
          .watch(doctorsRepositoryProvider)
          .schedule(doctorId, from: from);
    });

final doctorReviewsProvider = FutureProvider.autoDispose
    .family<List<DoctorReview>, String>(
      (ref, doctorId) => ref.watch(doctorsRepositoryProvider).reviews(doctorId),
    );

final appointmentProvider = FutureProvider.family<Appointment, String>(
  (ref, id) => ref.watch(doctorsRepositoryProvider).appointment(id),
);

/// Активные записи пользователя в листе ожидания.
///
/// После выхода или принятия предложения provider инвалидируется экраном,
/// чтобы состояние всегда повторно читалось с сервера.
final waitlistEntriesProvider = FutureProvider.autoDispose<List<WaitlistEntry>>(
  (ref) => ref.watch(doctorsRepositoryProvider).waitlistEntries(),
);

/// Отзывы, написанные пользователем на экране врача.
///
/// ОТПРАВЛЯТЬ ПО-ПРЕЖНЕМУ НЕКУДА, но причина сменилась. Читать отзывы уже
/// есть откуда (`GET /doctors/{id}/reviews`), а вот пишутся они не врачу, а
/// консультации: `POST /consultations/{id}/review`. Оценить можно только ту
/// консультацию, которая состоялась, а консультации в приложении пока нет
/// вовсе — ни созвона, ни идентификатора. Пока её не будет, написанное
/// встаёт первым в карусели, как своя реплика в переписке, и живёт до
/// перезапуска. Отдельно от [doctorReviewsProvider], чтобы не подменять
/// собой то, что придёт с сервера.
class ComposedReviews extends Notifier<List<DoctorReview>> {
  @override
  List<DoctorReview> build() => const [];

  void add({
    required String text,
    required String authorName,
    required double rating,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    state = [
      DoctorReview(
        id: 'own-${now.microsecondsSinceEpoch}',
        authorName: authorName,
        rating: rating,
        text: trimmed,
        createdAt: now,
      ),
      ...state,
    ];
  }
}

final composedReviewsProvider =
    NotifierProvider<ComposedReviews, List<DoctorReview>>(ComposedReviews.new);

/// Что пользователь выбрал в ленте расписания.
///
/// Оба поля пустые, пока он ничего не трогал: значение по умолчанию не
/// записывается в состояние, а выводится из расписания в [resolve]. Иначе
/// пришлось бы дописывать состояние из `build`, а это запрещено.
class ScheduleSelection {
  const ScheduleSelection({this.day, this.slot});

  final ScheduleDay? day;

  /// Слот выбранного дня. Сбрасывается при переключении дня: время из
  /// вторника в среде не действует.
  final ScheduleSlot? slot;

  /// Что показать выбранным: сначала выбор пользователя, иначе первый
  /// доступный день и его первый слот.
  ({ScheduleDay? day, ScheduleSlot? slot}) resolve(DoctorSchedule schedule) {
    final effectiveDay = day ?? schedule.firstAvailable;
    return (day: effectiveDay, slot: slot ?? effectiveDay?.firstSlot);
  }
}

/// Выбор дня и времени. Живёт на экране, не в репозитории: до нажатия
/// «Создать запись» на бэкенд ничего не уходит.
class ScheduleSelectionNotifier extends Notifier<ScheduleSelection> {
  @override
  ScheduleSelection build() => const ScheduleSelection();

  void selectDay(ScheduleDay day) {
    if (!day.isAvailable) return;
    // Слот намеренно не переносится: в новом дне он может быть занят.
    state = ScheduleSelection(day: day);
  }

  void selectSlot(ScheduleSlot slot) =>
      state = ScheduleSelection(day: state.day, slot: slot);

  /// Сбрасывается при листании недель: выбранный день остался в предыдущей
  /// ленте, и подсветка встала бы на чужое число.
  void reset() => state = const ScheduleSelection();
}

final scheduleSelectionProvider =
    NotifierProvider<ScheduleSelectionNotifier, ScheduleSelection>(
      ScheduleSelectionNotifier.new,
    );
