import 'package:medix/features/chats/data/repositories/chats_repository.dart';
import 'package:medix/features/chats/domain/entities/chat_thread.dart';
import 'package:medix/features/telemedicine/data/services/consultation_file_picker.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

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
  Future<List<ConsultationFile>> files(String threadId) async => const [];

  @override
  Future<ConsultationFile> uploadFile(
    String threadId,
    PickedConsultationFile file,
  ) async => ConsultationFile(
    id: 'file',
    consultationId: threadId,
    uploadedBy: 'user',
    createdAt: DateTime(2026, 8, 24),
  );

  @override
  Future<ConsultationFileDownload> fileDownload(
    String threadId,
    String fileId,
  ) async => ConsultationFileDownload(
    url: 'https://example.com/$fileId',
    expiresAt: DateTime(2026, 8, 24, 12),
  );

  @override
  Future<void> closeChat(String threadId) async {}
}
