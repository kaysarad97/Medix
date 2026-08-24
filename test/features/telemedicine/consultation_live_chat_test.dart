import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/consultation_live_chat.dart';
import 'package:medix/features/telemedicine/data/repositories/consultation_socket.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('один канал доставляет history, входящие и echo отправки', () async {
    final socket = _ControllableSocket();
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/join': (
        statusCode: 200,
        body: {
          'room_id': 'room-c1',
          'ws_ticket': 'short-ticket',
          'video_token': 'video-token',
          'video_server_url': 'wss://video.medix.kz',
          'mode': 'video',
          'expires_at': '2026-08-24T12:00:00Z',
        },
      ),
    });
    final live = ConsultationLiveChat(
      ConsultationsRepository(dio),
      socketFactory: () => socket,
    );
    final received = <ConsultationMessage>[];
    final subscription = live.watch('c1', userId: 'u1').listen(received.add);
    await pumpEventQueue();

    socket.add(ConsultationHistoryEvent([message('history', sender: 'u2')]));
    socket.add(ConsultationMessageEvent(message('incoming', sender: 'u2')));
    await pumpEventQueue();

    final sending = live.send('c1', userId: 'u1', body: 'Ответ');
    await pumpEventQueue();
    socket.add(
      ConsultationMessageEvent(message('echo', sender: 'u1', body: 'Ответ')),
    );
    final sent = await sending;
    await pumpEventQueue();

    expect(adapter.requests, hasLength(1));
    expect(socket.ticket, 'short-ticket');
    expect(socket.sent, ['Ответ']);
    expect(received.map((item) => item.id), ['history', 'incoming', 'echo']);
    expect(sent.id, 'echo');

    await live.close('c1');
    await subscription.cancel();
    expect(socket.closed, isTrue);
  });
}

ConsultationMessage message(
  String id, {
  required String sender,
  String body = 'Сообщение',
}) => ConsultationMessage(
  id: id,
  consultationId: 'c1',
  senderId: sender,
  body: body,
  createdAt: DateTime.utc(2026, 8, 24, 10, id.length),
);

class _ControllableSocket extends ConsultationSocket {
  final _events = StreamController<ConsultationSocketEvent>();
  final sent = <String>[];
  String? ticket;
  bool closed = false;

  @override
  Stream<ConsultationSocketEvent> connect({
    required String consultationId,
    required String ticket,
  }) {
    this.ticket = ticket;
    return _events.stream;
  }

  void add(ConsultationSocketEvent event) => _events.add(event);

  @override
  void send(String body) => sent.add(body);

  @override
  Future<void> close() async {
    closed = true;
    await _events.close();
  }
}
