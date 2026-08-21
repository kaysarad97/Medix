import 'package:medix/features/doctor_cabinet/data/repositories/doctor_chatbot_repository.dart';
import 'package:medix/shared/models/chat_message.dart';

/// Заглушка бота с предсказуемой задержкой: у боевой она 1200 мс, ждать
/// столько в каждом тесте незачем.
class FakeDoctorChatbotRepository implements DoctorChatbotRepository {
  const FakeDoctorChatbotRepository();

  static const Duration delay = Duration(milliseconds: 50);

  @override
  List<QuickReply> quickReplies() =>
      const MockDoctorChatbotRepository().quickReplies();

  @override
  Future<ChatMessage> reply(String prompt) async {
    await Future<void>.delayed(delay);
    return ChatMessage(
      id: 'bot-test',
      author: ChatAuthor.bot,
      text: 'Ответ на «$prompt»',
      sentAt: DateTime(2026, 8, 3),
    );
  }
}
