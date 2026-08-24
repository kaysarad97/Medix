import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/'
    'consultation_socket.dart';
import 'package:medix/features/telemedicine/data/repositories/'
    'consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('читает список собственных консультаций с фильтром', () async {
    final (:dio, :adapter) = cannedDio({
      '/consultations': (
        statusCode: 200,
        body: [
          {
            'id': 'c1',
            'appointment_id': 'a1',
            'status': 'completed',
            'started_at': '2026-08-21T10:00:00Z',
            'ended_at': '2026-08-21T10:30:00Z',
          },
        ],
      ),
    });

    final result = await ConsultationsRepository(
      dio,
    ).consultations(status: ConsultationStatus.completed);

    expect(result.single.appointmentId, 'a1');
    expect(result.single.status, ConsultationStatus.completed);
    expect(adapter.requests.single.queryParameters, {
      'status': 'completed',
      'limit': 100,
      'offset': 0,
    });
  });

  test('вход возвращает реквизиты чата и видеокомнаты', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/join': (
        statusCode: 200,
        body: {
          'room_id': 'consultation-c1',
          'ws_ticket': 'ws-token',
          'video_token': 'livekit-token',
          'video_server_url': 'wss://video.medix.kz',
          'mode': 'audio',
          'expires_at': '2026-08-21T12:00:00Z',
        },
      ),
    });

    final result = await ConsultationsRepository(dio).join('c1');

    expect(result.mode, ConsultationMode.audio);
    expect(result.videoToken, 'livekit-token');
    expect(adapter.requests.single.path, '/consultations/c1/join');
  });

  test('завершение консультации разбирает состояние', () async {
    final (:dio, :adapter) = cannedDio({
      'PATCH /consultations/c1/complete': (
        statusCode: 200,
        body: {
          'id': 'c1',
          'appointment_id': 'a1',
          'status': 'completed',
          'started_at': '2026-08-21T10:00:00Z',
          'ended_at': '2026-08-21T10:30:00Z',
        },
      ),
    });

    final result = await ConsultationsRepository(dio).complete('c1');

    expect(result.status, ConsultationStatus.completed);
    expect(result.endedAt, isNotNull);
    expect(adapter.requests.single.method, 'PATCH');
  });

  test('история сообщений сохраняет отправителя', () async {
    final (:dio, :adapter) = cannedDio({
      'GET /consultations/c1/messages': (
        statusCode: 200,
        body: [
          {
            'id': 'm1',
            'consultation_id': 'c1',
            'sender_id': 'u1',
            'body': 'Здравствуйте',
            'created_at': '2026-08-21T10:01:00Z',
          },
        ],
      ),
    });

    final result = await ConsultationsRepository(dio).messages('c1');

    expect(result.single.senderId, 'u1');
    expect(result.single.body, 'Здравствуйте');
    expect(adapter.requests.single.path, '/consultations/c1/messages');
  });

  test('отправка получает ticket и ждёт серверное подтверждение', () async {
    final socket = _FakeSocket();
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/join': (
        statusCode: 200,
        body: {
          'room_id': 'consultation-c1',
          'ws_ticket': 'short-ticket',
          'video_token': 'video-token',
          'video_server_url': 'wss://video.medix.kz',
          'mode': 'video',
          'expires_at': '2026-08-21T12:00:00Z',
        },
      ),
    });
    final repository = ConsultationsRepository(
      dio,
      socketFactory: () => socket,
    );

    final result = await repository.sendMessage(
      'c1',
      senderId: 'u1',
      body: 'Здравствуйте',
    );

    expect(result.id, 'server-message');
    expect(socket.ticket, 'short-ticket');
    expect(socket.sent, 'Здравствуйте');
    expect(socket.closed, isTrue);
    expect(adapter.requests.single.path, '/consultations/c1/join');
  });

  test('вложение проходит выдачу URL, подтверждение и скачивание', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/files/upload-url': (
        statusCode: 200,
        body: {
          'upload_url': 'https://storage.example/upload',
          'fields': {'policy': 'signed'},
          'key': 'consultations/c1/file.pdf',
          'expires_at': '2026-08-21T12:00:00Z',
        },
      ),
      'POST /consultations/c1/files': (statusCode: 200, body: _fileJson),
      'GET /consultations/c1/files/f1/download-url': (
        statusCode: 200,
        body: {
          'download_url': 'https://storage.example/file.pdf',
          'expires_at': '2026-08-21T13:00:00Z',
        },
      ),
    });
    final repository = ConsultationsRepository(dio);

    final ticket = await repository.requestFileUpload(
      'c1',
      filename: 'file.pdf',
      contentType: 'application/pdf',
    );
    final file = await repository.confirmFileUpload('c1', s3Key: ticket.key);
    final download = await repository.fileDownload('c1', file.id);

    expect(ticket.fields['policy'], 'signed');
    expect(download.url, endsWith('file.pdf'));
    expect(adapter.requests[1].data, {'s3_key': ticket.key});
  });

  test('список вложений и спор разбираются', () async {
    final (:dio, :adapter) = cannedDio({
      'GET /consultations/c1/files': (statusCode: 200, body: [_fileJson]),
      'POST /consultations/c1/dispute': (
        statusCode: 200,
        body: {
          'id': 'd1',
          'consultation_id': 'c1',
          'raised_by': 'u1',
          'reason': 'Связь прервалась',
          'status': 'open',
          'resolution': null,
          'resolved_by': null,
          'resolved_at': null,
          'created_at': '2026-08-21T11:00:00Z',
        },
      ),
    });
    final repository = ConsultationsRepository(dio);

    final files = await repository.files('c1');
    final dispute = await repository.dispute('c1', 'Связь прервалась');

    expect(files.single.uploadedBy, 'u1');
    expect(dispute.status, ConsultationDisputeStatus.open);
    expect(adapter.requests.last.data, {'reason': 'Связь прервалась'});
  });

  test('отзыв отправляется через завершённую консультацию', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/review': (
        statusCode: 201,
        body: {
          'id': 'r1',
          'doctor_id': 'd1',
          'author_id': 'u1',
          'author_name': 'Алия',
          'consultation_id': 'c1',
          'rating': 5,
          'body': 'Спасибо',
          'created_at': '2026-08-21T11:00:00Z',
        },
      ),
    });

    final review = await ConsultationsRepository(
      dio,
    ).review('c1', rating: 5, body: 'Спасибо');

    expect(review.authorName, 'Алия');
    expect(review.rating, 5);
    expect(adapter.requests.single.data, {'rating': 5, 'body': 'Спасибо'});
  });

  test('находит consultation_id для отзыва по doctor id', () async {
    final (:dio, :adapter) = cannedDio({
      '/consultations': (
        statusCode: 200,
        body: [
          {
            'id': 'c1',
            'appointment_id': 'a1',
            'status': 'completed',
            'started_at': '2026-08-21T10:00:00Z',
            'ended_at': '2026-08-21T10:30:00Z',
          },
        ],
      ),
      '/appointments/a1': (
        statusCode: 200,
        body: {
          'id': 'a1',
          'doctor': {'id': 'd1'},
        },
      ),
      'POST /consultations/c1/review': (
        statusCode: 201,
        body: {
          'id': 'r1',
          'doctor_id': 'd1',
          'author_id': 'u1',
          'author_name': 'Алия',
          'consultation_id': 'c1',
          'rating': 4,
          'body': 'Понятная консультация',
          'created_at': '2026-08-21T11:00:00Z',
        },
      ),
    });

    final review = await ConsultationsRepository(
      dio,
    ).reviewDoctor('d1', rating: 4, body: 'Понятная консультация');

    expect(review.id, 'r1');
    expect(adapter.requests.last.path, '/consultations/c1/review');
  });
}

const _fileJson = {
  'id': 'f1',
  'consultation_id': 'c1',
  'uploaded_by': 'u1',
  'created_at': '2026-08-21T10:30:00Z',
};

class _FakeSocket extends ConsultationSocket {
  final _events = StreamController<ConsultationSocketEvent>();
  String? ticket;
  String? sent;
  bool closed = false;

  @override
  Stream<ConsultationSocketEvent> connect({
    required String consultationId,
    required String ticket,
  }) {
    this.ticket = ticket;
    return _events.stream;
  }

  @override
  void send(String body) {
    sent = body;
    _events.add(
      ConsultationMessageEvent(
        ConsultationMessage(
          id: 'server-message',
          consultationId: 'c1',
          senderId: 'u1',
          body: body,
          createdAt: DateTime.utc(2026, 8, 21, 10, 1),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    closed = true;
    await _events.close();
  }
}
