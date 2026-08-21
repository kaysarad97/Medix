import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../telemedicine/presentation/providers/telemedicine_providers.dart';
import '../../data/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => DoctorsHomeRepository(ref.watch(doctorsRepositoryProvider)),
);

final specialtiesProvider = FutureProvider<List<DoctorSpecialty>>(
  (ref) => ref.watch(homeRepositoryProvider).specialties(),
);

final upcomingAppointmentsProvider = FutureProvider<List<Appointment>>(
  (ref) => ref.watch(homeRepositoryProvider).upcomingAppointments(),
);
