import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/chat_message.dart';
import '../../data/repositories/doctor_chatbot_repository.dart';

final doctorChatbotRepositoryProvider = Provider<DoctorChatbotRepository>(
  (ref) => const MockDoctorChatbotRepository(),
);

@immutable
class DoctorChatbotState {
  const DoctorChatbotState({
    this.messages = const [],
    this.botIsTyping = false,
  });

  final List<ChatMessage> messages;

  /// Бот «набирает» — в переписке показывается многоточие.
  final bool botIsTyping;

  /// Пустая переписка — «Чат-бот Старт»: вместо истории показываются часто
  /// задаваемые вопросы.
  bool get isEmpty => messages.isEmpty;

  DoctorChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? botIsTyping,
  }) {
    return DoctorChatbotState(
      messages: messages ?? this.messages,
      botIsTyping: botIsTyping ?? this.botIsTyping,
    );
  }
}

class DoctorChatbotController extends Notifier<DoctorChatbotState> {
  @override
  DoctorChatbotState build() => const DoctorChatbotState();

  List<QuickReply> get quickReplies =>
      ref.read(doctorChatbotRepositoryProvider).quickReplies();

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

    final answer = await ref
        .read(doctorChatbotRepositoryProvider)
        .reply(trimmed);
    state = state.copyWith(
      messages: [...state.messages, answer],
      botIsTyping: false,
    );
  }
}

final doctorChatbotControllerProvider =
    NotifierProvider<DoctorChatbotController, DoctorChatbotState>(
      DoctorChatbotController.new,
    );
