import '../../domain/entities/chat_message.dart';

abstract interface class ChatbotRepository {
  /// Быстрые вопросы для пустой переписки.
  List<QuickReply> quickReplies();

  /// Ответ бота на реплику пользователя.
  Future<ChatMessage> reply(String prompt);
}

/// Заглушка на время разработки бэкенда.
///
/// Настоящий бот живёт на сервере: распознаёт направление через OCR,
/// сравнивает цены партнёрских лабораторий и предлагает запись. Здесь только
/// форма диалога, чтобы экран можно было пройти руками.
class MockChatbotRepository implements ChatbotRepository {
  const MockChatbotRepository();

  @override
  List<QuickReply> quickReplies() => const [
    QuickReply(id: 'upload-analyses', text: 'Хочу загрузить анализы'),
    QuickReply(id: 'upload-referral', text: 'Хочу загрузить направление'),
    QuickReply(id: 'cheapest', text: 'Где дешевле сдать анализы?'),
  ];

  @override
  Future<ChatMessage> reply(String prompt) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return ChatMessage(
      id: 'bot-${DateTime.now().microsecondsSinceEpoch}',
      author: ChatAuthor.bot,
      text: _answerFor(prompt),
      sentAt: DateTime.now(),
    );
  }

  String _answerFor(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('направлен')) {
      return 'Пришлите фотографию направления — разберу список анализов '
          'и сравню цены в партнёрских лабораториях.';
    }
    if (lower.contains('дешевле') || lower.contains('цен')) {
      return 'Назовите анализ или пришлите направление, и я покажу, где '
          'в вашем городе он дешевле.';
    }
    if (lower.contains('анализ')) {
      return 'Приложите файл или фотографию результатов — подготовлю '
          'разбор показателей.';
    }
    return 'Отвечу, когда подключат бота. Пока это заглушка: настоящие '
        'ответы придут с сервера.';
  }
}
