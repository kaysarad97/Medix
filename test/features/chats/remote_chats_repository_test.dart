import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/chats/data/repositories/remote_chats_repository.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test(
    'собирает пациентский чат из консультации, записи и сообщений',
    () async {
      final (:dio, :adapter) = cannedDio({
        '/users/me': (statusCode: 200, body: {'id': 'patient-1'}),
        '/consultations': (
          statusCode: 200,
          body: [
            {
              'id': 'consultation-1',
              'appointment_id': 'appointment-1',
              'status': 'in_progress',
              'started_at': '2026-08-24T07:30:00Z',
              'ended_at': null,
            },
          ],
        ),
        '/appointments/appointment-1': (
          statusCode: 200,
          body: {
            'id': 'appointment-1',
            'starts_at': '2026-08-24T07:30:00Z',
            'doctor': {
              'id': 'doctor-1',
              'full_name': 'Айжан Садыкова',
              'specialty': 'Кардиолог',
              'photo_url': 'https://cdn.example/doctor.jpg',
              'clinic': null,
            },
          },
        ),
        '/consultations/consultation-1/messages': (
          statusCode: 200,
          body: [
            {
              'id': 'message-1',
              'consultation_id': 'consultation-1',
              'sender_id': 'patient-1',
              'body': 'Здравствуйте',
              'created_at': '2026-08-24T07:35:00Z',
            },
          ],
        ),
      });

      final threads = await RemoteChatsRepository(dio).threads();

      expect(threads.single.id, 'consultation-1');
      expect(threads.single.doctorId, 'doctor-1');
      expect(threads.single.doctorName, 'Айжан Садыкова');
      expect(threads.single.doctorPhotoUrl, endsWith('doctor.jpg'));
      expect(threads.single.lastMessage, 'Здравствуйте');
      expect(threads.single.lastMessageIsMine, isTrue);
      expect(threads.single.isRead, isTrue);
      expect(adapter.requests, hasLength(4));
    },
  );
}
