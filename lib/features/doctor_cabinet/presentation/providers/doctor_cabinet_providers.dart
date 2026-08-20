import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/doctor_cabinet_repository.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_own_profile.dart';
import '../../domain/entities/doctor_own_review.dart';
import '../../domain/entities/doctor_patient.dart';
import '../../domain/entities/regular_patient.dart';
import '../../domain/entities/work_analytics.dart';

final doctorCabinetRepositoryProvider = Provider<DoctorCabinetRepository>(
  (ref) => const MockDoctorCabinetRepository(),
);

final doctorUpcomingAppointmentsProvider =
    FutureProvider<List<DoctorAppointment>>(
      (ref) =>
          ref.watch(doctorCabinetRepositoryProvider).upcomingAppointments(),
    );

final doctorRegularPatientsProvider = FutureProvider<List<RegularPatient>>(
  (ref) => ref.watch(doctorCabinetRepositoryProvider).regularPatients(),
);

final doctorOwnProfileProvider = FutureProvider<DoctorOwnProfile>(
  (ref) => ref.watch(doctorCabinetRepositoryProvider).ownProfile(),
);

final doctorCertificatesProvider = FutureProvider<List<Certificate>>(
  (ref) => ref.watch(doctorCabinetRepositoryProvider).certificates(),
);

final doctorOwnReviewsProvider = FutureProvider<List<DoctorOwnReview>>(
  (ref) => ref.watch(doctorCabinetRepositoryProvider).ownReviews(),
);

/// Выбранный день календаря врача. Riverpod 3 не имеет `StateProvider` —
/// обычный `Notifier` вместо него.
class SelectedCalendarDay extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);

  /// Листает неделю целиком, сохраняя день недели — тот же приём, что у
  /// пациентской `ScheduleWeekOffset`, но без отдельного счётчика: страница
  /// не помнит смещение отдельно от выбранного дня.
  void previousWeek() => state = state.subtract(const Duration(days: 7));

  void nextWeek() => state = state.add(const Duration(days: 7));
}

final selectedCalendarDayProvider =
    NotifierProvider<SelectedCalendarDay, DateTime>(SelectedCalendarDay.new);

/// Перечитывается при каждой смене дня, а не кэшируется один раз — тот же
/// приём, что и у `doctorScheduleProvider` в телемедицине.
final doctorAppointmentsForDayProvider =
    FutureProvider.autoDispose<List<DoctorAppointment>>(
      (ref) => ref
          .watch(doctorCabinetRepositoryProvider)
          .appointmentsForDay(ref.watch(selectedCalendarDayProvider)),
    );

/// День, выбранный в полосе «Истории записей».
///
/// Отдельно от [selectedCalendarDayProvider]: календарь и история — разные
/// экраны с разными периодами (будущее против прошлого), и общий выбор
/// перетаскивал бы один за другим.
class SelectedHistoryDay extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);

  void previousMonth() =>
      state = DateTime(state.year, state.month - 1, state.day);

  void nextMonth() => state = DateTime(state.year, state.month + 1, state.day);
}

final selectedHistoryDayProvider =
    NotifierProvider<SelectedHistoryDay, DateTime>(SelectedHistoryDay.new);

/// На сколько недель назад отлистан блок «Другие записи». Ноль — неделя,
/// предшествующая выбранному дню.
///
/// Вперёд дальше нуля не пускаем: это история, будущих записей в ней нет —
/// для них есть календарь.
class HistoryWeekOffset extends Notifier<int> {
  @override
  int build() => 0;

  void previous() => state = state + 1;

  void next() {
    if (state > 0) state = state - 1;
  }
}

final historyWeekOffsetProvider = NotifierProvider<HistoryWeekOffset, int>(
  HistoryWeekOffset.new,
);

/// Промежуток, который сейчас показан в «Других записях».
({DateTime from, DateTime to}) historyWeekRange(DateTime day, int weeksBack) {
  final end = day.subtract(Duration(days: 1 + 7 * weeksBack));
  return (from: end.subtract(const Duration(days: 6)), to: end);
}

/// Строка поиска по имени пациента. Живёт в провайдере, а не в состоянии
/// экрана: список записей приходит из другого провайдера, и фильтровать
/// его надо там же, где он собирается.
class HistorySearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final historySearchQueryProvider = NotifierProvider<HistorySearchQuery, String>(
  HistorySearchQuery.new,
);

/// «Другие записи» за отлистанную неделю, отфильтрованные строкой поиска.
///
/// `autoDispose` — перечитывается при каждой смене дня и недели, тот же
/// приём, что у [doctorAppointmentsForDayProvider].
final doctorPastAppointmentsProvider =
    FutureProvider.autoDispose<List<DoctorAppointment>>((ref) async {
      final range = historyWeekRange(
        ref.watch(selectedHistoryDayProvider),
        ref.watch(historyWeekOffsetProvider),
      );
      final appointments = await ref
          .watch(doctorCabinetRepositoryProvider)
          .pastAppointments(from: range.from, to: range.to);

      final query = ref.watch(historySearchQueryProvider).trim().toLowerCase();
      if (query.isEmpty) return appointments;

      return [
        for (final appointment in appointments)
          if (appointment.patientName.toLowerCase().contains(query))
            appointment,
      ];
    });

/// «Предыдущая запись» — последняя перед выбранным днём.
final doctorPreviousAppointmentProvider =
    FutureProvider.autoDispose<DoctorAppointment?>((ref) async {
      final day = ref.watch(selectedHistoryDayProvider);
      final appointments = await ref
          .watch(doctorCabinetRepositoryProvider)
          .pastAppointments(
            from: day.subtract(const Duration(days: 7)),
            to: day,
          );
      return appointments.isEmpty ? null : appointments.last;
    });

final doctorPastAppointmentProvider = FutureProvider.autoDispose
    .family<DoctorAppointment, String>(
      (ref, id) =>
          ref.watch(doctorCabinetRepositoryProvider).pastAppointment(id),
    );

final doctorWorkAnalyticsProvider = FutureProvider<DoctorWorkAnalytics>(
  (ref) => ref.watch(doctorCabinetRepositoryProvider).workAnalytics(),
);

/// Пациент по идентификатору — «Профиль пациента» и «Запись с пациентом».
final doctorPatientProvider = FutureProvider.autoDispose
    .family<DoctorPatient, String>(
      (ref, id) => ref.watch(doctorCabinetRepositoryProvider).patient(id),
    );
