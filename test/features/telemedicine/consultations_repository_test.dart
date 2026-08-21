import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

import '../../helpers/canned_dio.dart';

void main() {
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
}
