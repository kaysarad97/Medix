import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chats_repository.dart';
import '../../domain/entities/chat_thread.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>(
  (ref) => const MockChatsRepository(),
);

final chatThreadsProvider = FutureProvider<List<ChatThread>>(
  (ref) => ref.watch(chatsRepositoryProvider).threads(),
);

/// Строка поиска в списке чатов.
///
/// Обычный Notifier, а не StateProvider: в Riverpod 3 его убрали.
class ChatSearchQuery extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final chatSearchQueryProvider = NotifierProvider<ChatSearchQuery, String>(
  ChatSearchQuery.new,
);

/// Список с учётом поиска.
final visibleChatThreadsProvider = Provider<List<ChatThread>>((ref) {
  final threads = ref.watch(chatThreadsProvider).value ?? const [];
  final query = ref.watch(chatSearchQueryProvider).trim().toLowerCase();
  if (query.isEmpty) return threads;

  return threads
      .where(
        (t) =>
            t.doctorName.toLowerCase().contains(query) ||
            t.lastMessage.toLowerCase().contains(query),
      )
      .toList();
});

@immutable
class DoctorChatState {
  const DoctorChatState({this.messages = const [], this.isSending = false});

  final List<DoctorMessage> messages;
  final bool isSending;

  DoctorChatState copyWith({List<DoctorMessage>? messages, bool? isSending}) {
    return DoctorChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

/// Открытая переписка.
///
/// Без family: одновременно открыт всегда один чат, а экран сам сообщает,
/// какой именно, через [open].
class DoctorChatController extends Notifier<DoctorChatState> {
  String? _threadId;

  @override
  DoctorChatState build() => const DoctorChatState();

  Future<void> open(String threadId) async {
    if (_threadId == threadId) return;
    _threadId = threadId;
    state = const DoctorChatState();

    final loaded = await ref.read(chatsRepositoryProvider).messages(threadId);
    if (_threadId != threadId) return;
    state = state.copyWith(messages: loaded);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    final threadId = _threadId;
    if (trimmed.isEmpty || threadId == null || state.isSending) return;

    state = state.copyWith(isSending: true);
    final sent = await ref
        .read(chatsRepositoryProvider)
        .send(threadId, trimmed);
    state = state.copyWith(
      messages: [...state.messages, sent],
      isSending: false,
    );
  }
}

final doctorChatControllerProvider =
    NotifierProvider<DoctorChatController, DoctorChatState>(
      DoctorChatController.new,
    );
