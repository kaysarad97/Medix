import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/doctor_cabinet_repository.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_own_profile.dart';
import '../../domain/entities/doctor_own_review.dart';
import '../../domain/entities/regular_patient.dart';

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
