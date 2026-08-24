import 'package:medix/features/chats/data/repositories/chats_repository.dart';
import 'package:medix/features/chats/domain/entities/chat_thread.dart';

/// Заглушка с короткой задержкой. Данные берутся из статики боевого мока —
/// не через его методы, у тех своя пауза в 300 мс.
class FakeChatsRepository implements ChatsRepository {
  const FakeChatsRepository();

  static const Duration delay = Duration(milliseconds: 20);

  @override
  Future<List<ChatThread>> threads() async {
    await Future<void>.delayed(delay);
    return MockChatsRepository.sampleThreads;
  }

  @override
  Future<List<DoctorMessage>> messages(String threadId) async {
    await Future<void>.delayed(delay);
    return MockChatsRepository.sampleMessages;
  }

  @override
  Stream<DoctorMessage> watchMessages(String threadId) => const Stream.empty();

  @override
  Future<DoctorMessage> send(String threadId, String text) async {
    await Future<void>.delayed(delay);
    return DoctorMessage(
      id: 'sent',
      text: text,
      isMine: true,
      sentAt: DateTime(2026, 8, 3),
    );
  }

  @override
  Future<void> closeChat(String threadId) async {}
}
