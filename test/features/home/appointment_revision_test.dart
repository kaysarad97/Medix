import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/home/presentation/providers/home_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/fake_doctors_repository.dart';

void main() {
  test('изменение записи перечитывает список на главной', () async {
    final repository = _CountingDoctorsRepository();
    final container = ProviderContainer(
      overrides: [doctorsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(upcomingAppointmentsProvider.future);
    expect(repository.appointmentsCalls, 1);

    container.read(appointmentRevisionProvider.notifier).markChanged();
    await container.read(upcomingAppointmentsProvider.future);

    expect(repository.appointmentsCalls, 2);
  });
}

class _CountingDoctorsRepository extends FakeDoctorsRepository {
  int appointmentsCalls = 0;

  @override
  Future<List<Appointment>> appointments({bool upcoming = false}) {
    appointmentsCalls++;
    return super.appointments(upcoming: upcoming);
  }
}
