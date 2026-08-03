import 'package:medix/features/lab_chatbot/data/repositories/chatbot_repository.dart';
import 'package:medix/features/lab_chatbot/domain/entities/chat_message.dart';

/// Заглушка бота с предсказуемой задержкой: у боевой она 1200 мс, ждать
/// столько в каждом тесте незачем.
class FakeChatbotRepository implements ChatbotRepository {
  const FakeChatbotRepository();

  static const Duration delay = Duration(milliseconds: 50);

  @override
  List<QuickReply> quickReplies() =>
      const MockChatbotRepository().quickReplies();

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
