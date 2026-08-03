/// Кто написал сообщение.
enum ChatAuthor { bot, user }

/// Реплика в переписке с ботом.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final ChatAuthor author;
  final String text;
  final DateTime sentAt;

  bool get isBot => author == ChatAuthor.bot;
}

/// Готовый вопрос из списка «Часто задаваемые вопросы».
class QuickReply {
  const QuickReply({required this.id, required this.text});

  final String id;
  final String text;
}
