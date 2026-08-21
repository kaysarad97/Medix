import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../telemedicine/data/repositories/doctors_repository.dart';

abstract interface class HomeRepository {
  Future<List<DoctorSpecialty>> specialties();

  Future<List<Appointment>> upcomingAppointments();
}

/// Home reads the same doctor catalogue and appointments as telemedicine.
/// Keeping this adapter avoids a second, drifting API implementation for the
/// home screen while preserving its small presentation-facing contract.
class DoctorsHomeRepository implements HomeRepository {
  const DoctorsHomeRepository(this._doctorsRepository);

  final DoctorsRepository _doctorsRepository;

  @override
  Future<List<DoctorSpecialty>> specialties() =>
      _doctorsRepository.specialties();

  @override
  Future<List<Appointment>> upcomingAppointments() =>
      _doctorsRepository.appointments(upcoming: true);
}

/// Заглушка на время разработки бэкенда. Данные — те же, что на макете
/// `design/Главная.png`.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  @override
  Future<List<DoctorSpecialty>> specialties() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      DoctorSpecialty(id: 'therapist', title: 'Терапевт', doctorCount: 100),
      DoctorSpecialty(id: 'pediatrician', title: 'Педиатр', doctorCount: 100),
      DoctorSpecialty(id: 'cardiologist', title: 'Кардиолог', doctorCount: 48),
      DoctorSpecialty(id: 'neurologist', title: 'Невролог', doctorCount: 32),
    ];
  }

  @override
  Future<List<Appointment>> upcomingAppointments() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      Appointment(
        id: 'a1',
        specialty: 'Кардиолог',
        kind: AppointmentKind.videoCall,
        startsAt: DateTime(2026, 8, 13, 10, 30),
      ),
      Appointment(
        id: 'a2',
        specialty: 'Кардиолог',
        kind: AppointmentKind.videoCall,
        startsAt: DateTime(2026, 8, 13, 15, 0),
      ),
    ];
  }
}
