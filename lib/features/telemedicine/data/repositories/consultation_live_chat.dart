import 'dart:async';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/consultation.dart';
import 'consultation_socket.dart';
import 'consultations_repository.dart';

/// Пул живых WebSocket-сеансов: один канал на одну открытую консультацию.
///
/// REST остаётся источником начальной истории, а этот слой доставляет
/// history/message события без перезагрузки экрана и подтверждает исходящую
/// реплику только после серверного echo.
class ConsultationLiveChat {
  ConsultationLiveChat(
    this._repository, {
    ConsultationSocket Function()? socketFactory,
  }) : _socketFactory = socketFactory ?? ConsultationSocket.new;

  final ConsultationsRepository _repository;
  final ConsultationSocket Function() _socketFactory;
  final Map<String, _LiveSession> _sessions = {};

  Stream<ConsultationMessage> watch(
    String consultationId, {
    required String userId,
  }) => _session(consultationId, userId).stream;

  Future<ConsultationMessage> send(
    String consultationId, {
    required String userId,
    required String body,
  }) => _session(consultationId, userId).send(body);

  Future<void> close(String consultationId) async {
    final session = _sessions.remove(consultationId);
    await session?.close();
  }

  Future<void> closeAll() async {
    final sessions = _sessions.values.toList();
    _sessions.clear();
    await Future.wait([for (final session in sessions) session.close()]);
  }

  _LiveSession _session(String consultationId, String userId) =>
      _sessions.putIfAbsent(
        consultationId,
        () => _LiveSession(
          consultationId: consultationId,
          userId: userId,
          repository: _repository,
          socketFactory: _socketFactory,
        ),
      );
}

class _LiveSession {
  _LiveSession({
    required this.consultationId,
    required this.userId,
    required this.repository,
    required this.socketFactory,
  }) {
    _messages = StreamController<ConsultationMessage>.broadcast(
      onListen: () {
        unawaited(_open().catchError((_) {}));
      },
    );
  }

  final String consultationId;
  final String userId;
  final ConsultationsRepository repository;
  final ConsultationSocket Function() socketFactory;

  late final StreamController<ConsultationMessage> _messages;
  final List<_PendingMessage> _pending = [];
  ConsultationSocket? _socket;
  StreamSubscription<ConsultationSocketEvent>? _subscription;
  Future<void>? _opening;
  var _connected = false;
  var _closed = false;

  Stream<ConsultationMessage> get stream => _messages.stream;

  Future<void> _open() {
    if (_closed) return Future.error(const ApiException('Чат уже закрыт'));
    if (_connected) return Future.value();
    final opening = _opening;
    if (opening != null) return opening;

    final future = _connect();
    _opening = future;
    return future.whenComplete(() {
      if (identical(_opening, future)) _opening = null;
    });
  }

  Future<void> _connect() async {
    try {
      await _subscription?.cancel();
      await _socket?.close();
      _subscription = null;

      final join = await repository.join(consultationId);
      if (_closed) return;
      final socket = socketFactory();
      _socket = socket;
      _connected = true;
      _subscription = socket
          .connect(consultationId: consultationId, ticket: join.webSocketTicket)
          .listen(
            _onEvent,
            onError: (Object error, StackTrace stackTrace) {
              _onDisconnected(socket, error, stackTrace);
            },
            onDone: () {
              _onDisconnected(
                socket,
                const ApiException('Соединение с чатом закрыто'),
              );
            },
          );
    } catch (error, stackTrace) {
      _connected = false;
      if (!_messages.isClosed) _messages.addError(error, stackTrace);
      rethrow;
    }
  }

  void _onDisconnected(
    ConsultationSocket source,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!identical(_socket, source) || !_connected) return;
    _connected = false;
    _failPending(error, stackTrace);
    if (!_messages.isClosed) _messages.addError(error, stackTrace);
  }

  void _onEvent(ConsultationSocketEvent event) {
    switch (event) {
      case ConsultationHistoryEvent(:final messages):
        for (final message in messages) {
          if (!_messages.isClosed) _messages.add(message);
        }
      case ConsultationMessageEvent(:final message):
        if (!_messages.isClosed) _messages.add(message);
        for (final pending in _pending.toList()) {
          if (message.senderId == userId && message.body == pending.body) {
            _pending.remove(pending);
            if (!pending.result.isCompleted) pending.result.complete(message);
            break;
          }
        }
      case ConsultationSocketErrorEvent(:final detail):
        final error = ApiException(detail);
        _failPending(error);
        if (!_messages.isClosed) _messages.addError(error);
    }
  }

  Future<ConsultationMessage> send(String body) async {
    if (_closed) throw const ApiException('Чат уже закрыт');
    await _open();
    final socket = _socket;
    if (!_connected || socket == null) {
      throw const ApiException('Соединение с чатом закрыто');
    }
    final pending = _PendingMessage(body);
    _pending.add(pending);
    socket.send(body);
    try {
      return await pending.result.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw const ApiException('Сервер не подтвердил отправку сообщения'),
      );
    } finally {
      _pending.remove(pending);
    }
  }

  void _failPending(Object error, [StackTrace? stackTrace]) {
    for (final pending in _pending.toList()) {
      if (!pending.result.isCompleted) {
        pending.result.completeError(error, stackTrace);
      }
    }
    _pending.clear();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    const error = ApiException('Чат закрыт');
    _failPending(error);
    _connected = false;
    await _subscription?.cancel();
    await _socket?.close();
    await _messages.close();
  }
}

class _PendingMessage {
  _PendingMessage(this.body);

  final String body;
  final Completer<ConsultationMessage> result = Completer();
}
