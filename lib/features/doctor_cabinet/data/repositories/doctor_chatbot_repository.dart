import '../../../../shared/models/chat_message.dart';

abstract interface class DoctorChatbotRepository {
  /// Быстрые вопросы для пустой переписки.
  List<QuickReply> quickReplies();

  /// Ответ бота на реплику врача.
  Future<ChatMessage> reply(String prompt);
}

/// Заглушка на время разработки бэкенда.
///
/// Настоящий Medi-bot для врача — клинический ассистент: дозировки,
/// совместимость препаратов, оформление направлений. Здесь только форма
/// диалога, чтобы экран можно было пройти руками — как и у лабораторного
/// бота (`MockChatbotRepository`), с которым эта заглушка не делит код:
/// вопросы и ответы разные, общая только форма сообщения ([ChatMessage]
/// из `shared/models`).
class MockDoctorChatbotRepository implements DoctorChatbotRepository {
  const MockDoctorChatbotRepository();

  @override
  List<QuickReply> quickReplies() => const [
    QuickReply(id: 'dosage', text: 'Высчитать дозу для пациента'),
    QuickReply(id: 'interactions', text: 'Препараты и их совместимость'),
    QuickReply(
      id: 'referral',
      text: 'Оформить направление и список анализов для пациента',
    ),
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
    if (lower.contains('доз')) {
      return 'Укажите препарат, вес и возраст пациента — рассчитаю дозу.';
    }
    if (lower.contains('совмест') || lower.contains('препарат')) {
      return 'Назовите оба препарата, и я проверю совместимость.';
    }
    if (lower.contains('направлен') || lower.contains('анализ')) {
      return 'Укажите диагноз или подозрение — соберу список анализов для '
          'направления.';
    }
    return 'Отвечу, когда подключат бота. Пока это заглушка: настоящие '
        'ответы придут с сервера.';
  }
}
