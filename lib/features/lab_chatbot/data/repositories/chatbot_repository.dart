import '../../domain/entities/chat_message.dart';

abstract interface class ChatbotRepository {
  /// Быстрые вопросы для пустой переписки.
  List<QuickReply> quickReplies();

  /// Ответ бота на реплику пользователя.
  Future<ChatMessage> reply(String prompt);

  /// Разбор прикреплённого файла с анализами: статус обработки и результат.
  Future<List<ChatMessage>> analyzeAttachment(String fileName);
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

  @override
  Future<List<ChatMessage>> analyzeAttachment(String fileName) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final analyzing = ChatMessage(
      id: 'bot-${DateTime.now().microsecondsSinceEpoch}',
      author: ChatAuthor.bot,
      text: 'Анализирую Ваши результаты…',
      sentAt: DateTime.now(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final ready = ChatMessage(
      id: 'bot-${DateTime.now().microsecondsSinceEpoch}',
      author: ChatAuthor.bot,
      text: 'Ваши результаты доступны для просмотра в Вашей мед-карте',
      sentAt: DateTime.now(),
    );
    return [analyzing, ready];
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
      return 'Пожалуйста, прикрепите файл в формате PDF, чтобы я смог '
          'проанализировать его.';
    }
    return 'Отвечу, когда подключат бота. Пока это заглушка: настоящие '
        'ответы придут с сервера.';
  }
}
