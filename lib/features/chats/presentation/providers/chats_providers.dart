import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/chats_repository.dart';
import '../../data/repositories/remote_chats_repository.dart';
import '../../domain/entities/chat_thread.dart';
import '../../../telemedicine/data/services/consultation_file_picker.dart';
import '../../../telemedicine/domain/entities/consultation.dart';

final chatsRepositoryProvider = Provider<ChatsRepository>((ref) {
  if (useMocks) return const MockChatsRepository();
  return RemoteChatsRepository(ref.watch(dioClientProvider));
});

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
  const DoctorChatState({
    this.messages = const [],
    this.files = const [],
    this.isSending = false,
    this.isUploading = false,
  });

  final List<DoctorMessage> messages;
  final List<ConsultationFile> files;
  final bool isSending;
  final bool isUploading;

  DoctorChatState copyWith({
    List<DoctorMessage>? messages,
    List<ConsultationFile>? files,
    bool? isSending,
    bool? isUploading,
  }) {
    return DoctorChatState(
      messages: messages ?? this.messages,
      files: files ?? this.files,
      isSending: isSending ?? this.isSending,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

/// Открытая переписка.
///
/// Без family: одновременно открыт всегда один чат, а экран сам сообщает,
/// какой именно, через [open].
class DoctorChatController extends Notifier<DoctorChatState> {
  String? _threadId;
  StreamSubscription<DoctorMessage>? _subscription;

  @override
  DoctorChatState build() {
    final repository = ref.read(chatsRepositoryProvider);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      final threadId = _threadId;
      if (threadId != null) unawaited(repository.closeChat(threadId));
    });
    return const DoctorChatState();
  }

  Future<void> open(String threadId) async {
    if (_threadId == threadId) return;
    final repository = ref.read(chatsRepositoryProvider);
    final previous = _threadId;
    await _subscription?.cancel();
    if (previous != null) await repository.closeChat(previous);

    _threadId = threadId;
    state = const DoctorChatState();
    _subscription = repository.watchMessages(threadId).listen((message) {
      if (_threadId == threadId) _merge([message]);
    }, onError: (_) {});

    final loaded = await repository.messages(threadId);
    if (_threadId != threadId) return;
    _merge(loaded);
    try {
      final files = await repository.files(threadId);
      if (_threadId == threadId && files.isNotEmpty) {
        state = state.copyWith(files: files);
      }
    } catch (_) {
      // Недоступный список вложений не должен ломать текстовую переписку.
    }
  }

  Future<void> uploadFile(PickedConsultationFile file) async {
    final threadId = _threadId;
    if (threadId == null || state.isUploading) return;

    state = state.copyWith(isUploading: true);
    try {
      final uploaded = await ref
          .read(chatsRepositoryProvider)
          .uploadFile(threadId, file);
      if (_threadId == threadId) {
        state = state.copyWith(
          files: [
            ...state.files.where((item) => item.id != uploaded.id),
            uploaded,
          ],
        );
      }
    } finally {
      if (_threadId == threadId) state = state.copyWith(isUploading: false);
    }
  }

  Future<ConsultationFileDownload> fileDownload(String fileId) {
    final threadId = _threadId;
    if (threadId == null) {
      throw StateError('Chat is not open');
    }
    return ref.read(chatsRepositoryProvider).fileDownload(threadId, fileId);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    final threadId = _threadId;
    if (trimmed.isEmpty || threadId == null || state.isSending) return;

    state = state.copyWith(isSending: true);
    try {
      final sent = await ref
          .read(chatsRepositoryProvider)
          .send(threadId, trimmed);
      if (_threadId == threadId) _merge([sent]);
    } finally {
      if (_threadId == threadId) state = state.copyWith(isSending: false);
    }
  }

  void _merge(Iterable<DoctorMessage> incoming) {
    final byId = {for (final message in state.messages) message.id: message};
    for (final message in incoming) {
      byId[message.id] = message;
    }
    final messages = byId.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    state = state.copyWith(messages: messages);
  }
}

final doctorChatControllerProvider =
    NotifierProvider<DoctorChatController, DoctorChatState>(
      DoctorChatController.new,
    );
