import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../data/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockHomeRepository(),
);

final specialtiesProvider = FutureProvider<List<DoctorSpecialty>>(
  (ref) => ref.watch(homeRepositoryProvider).specialties(),
);

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>(
  (ref) => ref.watch(homeRepositoryProvider).upcomingAppointments(),
);
