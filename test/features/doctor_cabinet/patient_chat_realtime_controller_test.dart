import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/patient_chat.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';

void main() {
  test(
    'контроллер врача объединяет REST и realtime без дублей и закрывает чат',
    () async {
      final repository = _LiveDoctorCabinetRepository();
      final container = ProviderContainer(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(repository),
        ],
      );
      final subscription = container.listen(
        patientChatControllerProvider,
        (_, _) {},
      );

      await container.read(patientChatControllerProvider.notifier).open('c1');
      repository.incoming.add(repository.initial);
      repository.incoming.add(
        PatientMessage(
          id: 'incoming',
          text: 'Новая реплика пациента',
          isMine: false,
          sentAt: DateTime(2026, 8, 24, 10, 2),
        ),
      );
      await pumpEventQueue();

      final state = container.read(patientChatControllerProvider);
      expect(state.messages.map((item) => item.id), ['initial', 'incoming']);

      subscription.close();
      container.dispose();
      await pumpEventQueue();
      expect(repository.closed, ['c1']);
    },
  );
}

class _LiveDoctorCabinetRepository extends FakeDoctorCabinetRepository {
  _LiveDoctorCabinetRepository();

  final incoming = StreamController<PatientMessage>.broadcast();
  final closed = <String>[];

  final initial = PatientMessage(
    id: 'initial',
    text: 'История',
    isMine: true,
    sentAt: DateTime(2026, 8, 24, 10),
  );

  @override
  Future<List<PatientMessage>> patientMessages(String threadId) async => [
    initial,
  ];

  @override
  Stream<PatientMessage> watchPatientMessages(String threadId) =>
      incoming.stream;

  @override
  Future<void> closePatientChat(String threadId) async {
    closed.add(threadId);
    await incoming.close();
  }
}
