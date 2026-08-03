import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chatbot_repository.dart';
import '../../domain/entities/chat_message.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>(
  (ref) => const MockChatbotRepository(),
);

@immutable
class ChatbotState {
  const ChatbotState({this.messages = const [], this.botIsTyping = false});

  final List<ChatMessage> messages;

  /// Бот «набирает» — в переписке показывается многоточие.
  final bool botIsTyping;

  /// Пустая переписка — тот самый экран «Чат-бот Старт»: вместо истории
  /// показываются часто задаваемые вопросы.
  bool get isEmpty => messages.isEmpty;

  ChatbotState copyWith({List<ChatMessage>? messages, bool? botIsTyping}) {
    return ChatbotState(
      messages: messages ?? this.messages,
      botIsTyping: botIsTyping ?? this.botIsTyping,
    );
  }
}

class ChatbotController extends Notifier<ChatbotState> {
  @override
  ChatbotState build() => const ChatbotState();

  List<QuickReply> get quickReplies =>
      ref.read(chatbotRepositoryProvider).quickReplies();

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.botIsTyping) return;

    final outgoing = ChatMessage(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      author: ChatAuthor.user,
      text: trimmed,
      sentAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, outgoing],
      botIsTyping: true,
    );

    final answer = await ref.read(chatbotRepositoryProvider).reply(trimmed);
    state = state.copyWith(
      messages: [...state.messages, answer],
      botIsTyping: false,
    );
  }
}

final chatbotControllerProvider =
    NotifierProvider<ChatbotController, ChatbotState>(ChatbotController.new);
