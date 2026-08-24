import '../../domain/entities/chat_thread.dart';
import '../../../telemedicine/data/services/consultation_file_picker.dart';
import '../../../telemedicine/domain/entities/consultation.dart';

abstract interface class ChatsRepository {
  Future<List<ChatThread>> threads();

  Future<List<DoctorMessage>> messages(String threadId);

  Stream<DoctorMessage> watchMessages(String threadId);

  Future<DoctorMessage> send(String threadId, String text);

  Future<List<ConsultationFile>> files(String threadId);

  Future<ConsultationFile> uploadFile(
    String threadId,
    PickedConsultationFile file,
  );

  Future<ConsultationFileDownload> fileDownload(String threadId, String fileId);

  Future<void> closeChat(String threadId);
}

/// Заглушка на время разработки бэкенда. Содержимое — с макетов
/// `design/Чаты с врачами.png` и `design/Чат с врачом.png`.
class MockChatsRepository implements ChatsRepository {
  const MockChatsRepository();

  static final _sentAt = DateTime(2026, 7, 21, 13, 44);

  /// Данные отдельно от задержки: тесты берут их напрямую, чтобы не ждать
  /// сетевую паузу, которой всё равно нет.
  static List<ChatThread> get sampleThreads => [
    ChatThread(
      id: 't1',
      doctorName: 'Имя Фамилия',
      lastMessage: 'Здравствуйте! Какие анализы мне стоит сдать?',
      lastMessageAt: _sentAt,
      lastMessageIsMine: true,
      isRead: false,
    ),
    ChatThread(
      id: 't2',
      doctorName: 'Имя Фамилия',
      lastMessage: 'Спасибо за обращение, на здоровье!',
      lastMessageAt: _sentAt,
      lastMessageIsMine: false,
    ),
    ChatThread(
      id: 't3',
      doctorName: 'Имя Фамилия',
      lastMessage: 'Какой можно улучшить результаты для следующего приёма?',
      lastMessageAt: _sentAt,
      lastMessageIsMine: true,
    ),
    ChatThread(
      id: 't4',
      doctorName: 'Имя Фамилия',
      lastMessage: 'Запись подтверждена, спасибо!',
      lastMessageAt: _sentAt,
      lastMessageIsMine: false,
    ),
  ];

  static List<DoctorMessage> get sampleMessages => [
    DoctorMessage(
      id: 'm1',
      text: 'Здравствуйте! Какие анализы мне стоит сдать?',
      isMine: true,
      sentAt: _sentAt,
    ),
    DoctorMessage(
      id: 'm2',
      text:
          'Здравствуйте! Список анализов для приема определяется '
          'индивидуально. Прошу описать Ваши симптомы или создать '
          'видео-звонок для Вашего удобства.',
      isMine: false,
      sentAt: _sentAt.add(const Duration(minutes: 2)),
    ),
  ];

  @override
  Future<List<ChatThread>> threads() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return sampleThreads;
  }

  @override
  Future<List<DoctorMessage>> messages(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return sampleMessages;
  }

  @override
  Stream<DoctorMessage> watchMessages(String threadId) => const Stream.empty();

  @override
  Future<DoctorMessage> send(String threadId, String text) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return DoctorMessage(
      id: 'm-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      isMine: true,
      sentAt: DateTime.now(),
    );
  }

  @override
  Future<List<ConsultationFile>> files(String threadId) async => const [];

  @override
  Future<ConsultationFile> uploadFile(
    String threadId,
    PickedConsultationFile file,
  ) async => ConsultationFile(
    id: 'mock-file-${DateTime.now().microsecondsSinceEpoch}',
    consultationId: threadId,
    uploadedBy: 'mock-user',
    createdAt: DateTime.now(),
  );

  @override
  Future<ConsultationFileDownload> fileDownload(
    String threadId,
    String fileId,
  ) async => ConsultationFileDownload(
    url: 'https://example.com/$fileId',
    expiresAt: DateTime.now().add(const Duration(minutes: 5)),
  );

  @override
  Future<void> closeChat(String threadId) async {}
}
