import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/calls/data/call_media_session.dart';
import 'package:medix/features/calls/presentation/providers/call_session_controller.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test(
    'подключает LiveKit, переключает медиа и завершает приём врачом',
    () async {
      final (:dio, :adapter) = cannedDio({
        'POST /consultations/c1/join': (
          statusCode: 200,
          body: joinJson(mode: 'video'),
        ),
        'PATCH /consultations/c1/complete': (
          statusCode: 200,
          body: {
            'id': 'c1',
            'appointment_id': 'a1',
            'status': 'completed',
            'started_at': '2026-08-24T10:00:00Z',
            'ended_at': '2026-08-24T10:30:00Z',
          },
        ),
      });
      final media = _FakeCallMediaSession();
      final controller = CallSessionController(
        ConsultationsRepository(dio),
        media,
      );

      await controller.connect('c1', enableVideo: true);
      expect(controller.state.status, CallSessionStatus.connected);
      expect(controller.state.microphoneEnabled, isTrue);
      expect(controller.state.cameraEnabled, isTrue);
      expect(media.serverUrl, 'wss://video.medix.kz');
      expect(media.token, 'livekit-token');

      await controller.toggleCamera();
      await controller.toggleMicrophone();
      expect(controller.state.cameraEnabled, isFalse);
      expect(controller.state.microphoneEnabled, isFalse);

      await controller.hangUp(completeConsultation: true);
      expect(controller.state.status, CallSessionStatus.ended);
      expect(media.disconnected, isTrue);
      expect(adapter.requests.map((request) => request.path), [
        '/consultations/c1/join',
        '/consultations/c1/complete',
      ]);

      controller.dispose();
    },
  );

  test(
    'аудиоконсультация не включает камеру и пациент не завершает приём',
    () async {
      final (:dio, :adapter) = cannedDio({
        'POST /consultations/c1/join': (
          statusCode: 200,
          body: joinJson(mode: 'audio'),
        ),
      });
      final media = _FakeCallMediaSession();
      final controller = CallSessionController(
        ConsultationsRepository(dio),
        media,
      );

      await controller.connect('c1', enableVideo: true);
      expect(controller.state.supportsVideo, isFalse);
      expect(media.cameraEnabled, isFalse);

      await controller.hangUp(completeConsultation: false);
      expect(adapter.requests, hasLength(1));

      controller.dispose();
    },
  );

  test('сброс во время join не оставляет позднее LiveKit-соединение', () async {
    final (:dio, adapter: _) = cannedDio({});
    final repository = _DelayedConsultationsRepository(dio);
    final media = _FakeCallMediaSession();
    final controller = CallSessionController(repository, media);

    final connecting = controller.connect('c1', enableVideo: true);
    await controller.hangUp(completeConsultation: false);
    repository.joinResult.complete(
      ConsultationJoin(
        roomId: 'room-c1',
        webSocketTicket: 'ticket',
        videoToken: 'token',
        videoServerUrl: 'wss://video.medix.kz',
        mode: ConsultationMode.video,
        expiresAt: DateTime(2026, 8, 24, 12),
      ),
    );
    await connecting;

    expect(controller.state.status, CallSessionStatus.ended);
    expect(media.serverUrl, isNull);

    controller.dispose();
  });

  test('ошибка отключения не мешает врачу завершить консультацию', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /consultations/c1/join': (
        statusCode: 200,
        body: joinJson(mode: 'audio'),
      ),
      'PATCH /consultations/c1/complete': (
        statusCode: 200,
        body: {
          'id': 'c1',
          'appointment_id': 'a1',
          'status': 'completed',
          'started_at': '2026-08-24T10:00:00Z',
          'ended_at': '2026-08-24T10:30:00Z',
        },
      ),
    });
    final controller = CallSessionController(
      ConsultationsRepository(dio),
      _FakeCallMediaSession(failDisconnect: true),
    );

    await controller.connect('c1', enableVideo: false);
    await controller.hangUp(completeConsultation: true);

    expect(controller.state.status, CallSessionStatus.ended);
    expect(controller.state.errorMessage, 'disconnect failed');
    expect(adapter.requests.last.path, '/consultations/c1/complete');

    controller.dispose();
  });
}

Map<String, dynamic> joinJson({required String mode}) => {
  'room_id': 'room-c1',
  'ws_ticket': 'short-ticket',
  'video_token': 'livekit-token',
  'video_server_url': 'wss://video.medix.kz',
  'mode': mode,
  'expires_at': '2026-08-24T12:00:00Z',
};

class _DelayedConsultationsRepository extends ConsultationsRepository {
  _DelayedConsultationsRepository(super.dio);

  final joinResult = Completer<ConsultationJoin>();

  @override
  Future<ConsultationJoin> join(String consultationId) => joinResult.future;
}

class _FakeCallMediaSession extends CallMediaSession {
  _FakeCallMediaSession({this.failDisconnect = false});

  final bool failDisconnect;

  @override
  bool isConnected = false;

  @override
  bool microphoneEnabled = false;

  @override
  bool cameraEnabled = false;

  @override
  CallVideoFeed? get localVideo => null;

  @override
  CallVideoFeed? get remoteVideo => null;

  String? serverUrl;
  String? token;
  bool disconnected = false;

  @override
  Future<void> connect(
    ConsultationJoin join, {
    required bool enableVideo,
  }) async {
    serverUrl = join.videoServerUrl;
    token = join.videoToken;
    isConnected = true;
    microphoneEnabled = true;
    cameraEnabled = enableVideo;
    notifyListeners();
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    cameraEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    microphoneEnabled = enabled;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    if (failDisconnect) throw Exception('disconnect failed');
    disconnected = true;
    isConnected = false;
    cameraEnabled = false;
    microphoneEnabled = false;
    notifyListeners();
  }
}
