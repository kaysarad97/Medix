import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/chats/data/repositories/chats_repository.dart';
import 'package:medix/features/chats/domain/entities/chat_thread.dart';
import 'package:medix/features/chats/presentation/providers/chats_providers.dart';

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
  Future<void> closeChat(String threadId) async {
    closed.add(threadId);
    await incoming.close();
  }
}
