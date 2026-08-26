import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/'
    'consultation_socket.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

void main() {
  test('подключение передаёт короткоживущий ticket и читает историю', () async {
    final channel = _FakeChannel();
    late Uri connectedUri;
    final socket = ConsultationSocket(
      channelFactory: (uri) {
        connectedUri = uri;
        return channel;
      },
    );

    final first = socket
        .connect(consultationId: 'c1', ticket: 'short-ticket')
        .first;
    channel.incoming.add(
      jsonEncode({
        'type': 'history',
        'messages': [_messageJson],
      }),
    );

    final event = await first;
    expect(connectedUri.scheme, 'ws');
    expect(connectedUri.path, '/ws/consultations/c1');
    expect(connectedUri.queryParameters['ws_ticket'], 'short-ticket');
    expect(event, isA<ConsultationHistoryEvent>());
    expect((event as ConsultationHistoryEvent).messages.single.body, 'Привет');
    await socket.close();
  });

  test('новое сообщение разбирается, исходящее кодируется', () async {
    final channel = _FakeChannel();
    final socket = ConsultationSocket(channelFactory: (_) => channel);
    final next = socket.connect(consultationId: 'c1', ticket: 'ticket').first;

    socket.send('Здравствуйте');
    channel.incoming.add(jsonEncode({'type': 'message', ..._messageJson}));

    expect(jsonDecode(channel.sent.single), {'body': 'Здравствуйте'});
    final event = await next;
    expect(event, isA<ConsultationMessageEvent>());
    await socket.close();
  });

  test('ошибка сервера становится типизированным событием', () async {
    final channel = _FakeChannel();
    final socket = ConsultationSocket(channelFactory: (_) => channel);
    final next = socket.connect(consultationId: 'c1', ticket: 'ticket').first;
    channel.incoming.add(jsonEncode({'type': 'error', 'detail': 'Нельзя'}));

    final event = await next as ConsultationSocketErrorEvent;
    expect(event.detail, 'Нельзя');
    await socket.close();
  });
}

const _messageJson = {
  'id': 'm1',
  'consultation_id': 'c1',
  'sender_id': 'u1',
  'body': 'Привет',
  'created_at': '2026-08-21T10:01:00Z',
};

class _FakeChannel implements ConsultationSocketChannel {
  final incoming = StreamController<dynamic>();
  final sent = <String>[];

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  StreamSink<dynamic> get sink => _RecordingSink(sent, incoming);
}

class _RecordingSink implements StreamSink<dynamic> {
  _RecordingSink(this.sent, this.incoming);

  final List<String> sent;
  final StreamController<dynamic> incoming;

  @override
  void add(dynamic data) => sent.add(data as String);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      incoming.addError(error, stackTrace);

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final item in stream) {
      add(item);
    }
  }

  @override
  Future<void> close() => incoming.close();

  @override
  Future<void> get done => incoming.done;
}
