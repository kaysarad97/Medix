import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/home/data/repositories/home_repository.dart';
import 'package:medix/features/telemedicine/data/repositories/doctors_repository.dart';

void main() {
  test('home delegates catalogue and upcoming appointments', () async {
    const doctors = MockDoctorsRepository();
    final repository = DoctorsHomeRepository(doctors);

    final specialties = await repository.specialties();
    final appointments = await repository.upcomingAppointments();

    expect(specialties, await doctors.specialties());
    final expectedAppointments = await doctors.appointments(upcoming: true);
    expect(
      appointments.map((appointment) => appointment.id),
      expectedAppointments.map((appointment) => appointment.id),
    );
  });
}
