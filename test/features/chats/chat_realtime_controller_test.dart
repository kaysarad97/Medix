import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/chats/data/repositories/chats_repository.dart';
import 'package:medix/features/chats/domain/entities/chat_thread.dart';
import 'package:medix/features/chats/presentation/providers/chats_providers.dart';
import 'package:medix/features/telemedicine/data/services/consultation_file_picker.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

void main() {
  test(
    'контроллер объединяет REST и realtime без дублей и закрывает чат',
    () async {
      final repository = _LiveChatsRepository();
      final container = ProviderContainer(
        overrides: [chatsRepositoryProvider.overrideWithValue(repository)],
      );
      final subscription = container.listen(
        doctorChatControllerProvider,
        (_, _) {},
      );

      await container.read(doctorChatControllerProvider.notifier).open('c1');
      repository.incoming.add(repository.initial);
      repository.incoming.add(
        DoctorMessage(
          id: 'incoming',
          text: 'Новая реплика',
          isMine: false,
          sentAt: DateTime(2026, 8, 24, 10, 2),
        ),
      );
      await pumpEventQueue();

      final state = container.read(doctorChatControllerProvider);
      expect(state.messages.map((item) => item.id), ['initial', 'incoming']);

      subscription.close();
      container.dispose();
      await pumpEventQueue();
      expect(repository.closed, ['c1']);
    },
  );

  test('контроллер загружает и добавляет подтверждённое вложение', () async {
    final repository = _LiveChatsRepository();
    final container = ProviderContainer(
      overrides: [chatsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final controller = container.read(doctorChatControllerProvider.notifier);
    await controller.open('c1');
    expect(container.read(doctorChatControllerProvider).files, [
      repository.initialFile,
    ]);

    await controller.uploadFile(
      PickedConsultationFile(
        name: 'result.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    final state = container.read(doctorChatControllerProvider);
    expect(state.files.map((file) => file.id), ['existing', 'uploaded']);
    expect(state.isUploading, isFalse);
  });
}

class _LiveChatsRepository implements ChatsRepository {
  final incoming = StreamController<DoctorMessage>.broadcast();
  final closed = <String>[];

  final initial = DoctorMessage(
    id: 'initial',
    text: 'История',
    isMine: true,
    sentAt: DateTime(2026, 8, 24, 10),
  );

  final initialFile = ConsultationFile(
    id: 'existing',
    consultationId: 'c1',
    uploadedBy: 'doctor',
    createdAt: DateTime(2026, 8, 24, 9),
  );

  @override
  Future<List<ChatThread>> threads() async => const [];

  @override
  Future<List<DoctorMessage>> messages(String threadId) async => [initial];

  @override
  Stream<DoctorMessage> watchMessages(String threadId) => incoming.stream;

  @override
  Future<DoctorMessage> send(String threadId, String text) async =>
      DoctorMessage(
        id: 'sent',
        text: text,
        isMine: true,
        sentAt: DateTime(2026, 8, 24, 10, 3),
      );

  @override
  Future<List<ConsultationFile>> files(String threadId) async => [initialFile];

  @override
  Future<ConsultationFile> uploadFile(
    String threadId,
    PickedConsultationFile file,
  ) async => ConsultationFile(
    id: 'uploaded',
    consultationId: threadId,
    uploadedBy: 'patient',
    createdAt: DateTime(2026, 8, 24, 10),
  );

  @override
  Future<ConsultationFileDownload> fileDownload(
    String threadId,
    String fileId,
  ) => throw UnimplementedError();

  @override
  Future<void> closeChat(String threadId) async {
    closed.add(threadId);
    await incoming.close();
  }
}
