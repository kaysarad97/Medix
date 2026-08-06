import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../data/repositories/doctors_repository.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockDoctorsRepository(),
);

final doctorProvider = FutureProvider.family<Doctor, String>(
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
final doctorSearchResultsProvider = FutureProvider.family<List<Doctor>, String>(
  (ref, query) => ref.watch(doctorsRepositoryProvider).search(query),
);

final doctorScheduleProvider = FutureProvider.family<DoctorSchedule, String>(
  (ref, doctorId) => ref.watch(doctorsRepositoryProvider).schedule(doctorId),
);

final doctorReviewsProvider = FutureProvider.family<List<DoctorReview>, String>(
  (ref, doctorId) => ref.watch(doctorsRepositoryProvider).reviews(doctorId),
);

final appointmentProvider = FutureProvider.family<Appointment, String>(
  (ref, id) => ref.watch(doctorsRepositoryProvider).appointment(id),
);

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
  final DateTime? slot;

  /// Что показать выбранным: сначала выбор пользователя, иначе первый
  /// доступный день и его первый слот.
  ({ScheduleDay? day, DateTime? slot}) resolve(DoctorSchedule schedule) {
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

  void selectSlot(DateTime slot) =>
      state = ScheduleSelection(day: state.day, slot: slot);
}

final scheduleSelectionProvider =
    NotifierProvider<ScheduleSelectionNotifier, ScheduleSelection>(
      ScheduleSelectionNotifier.new,
    );
