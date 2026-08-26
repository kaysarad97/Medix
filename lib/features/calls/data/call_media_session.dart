import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../telemedicine/domain/entities/consultation.dart';

/// Видеопоток без протекания типов LiveKit в состояние экрана и тесты.
abstract interface class CallVideoFeed {
  Widget view({required bool mirror});
}

/// Медиасеанс звонка. Серверные реквизиты приходят из `join()`, а здесь
/// остаётся только lifecycle комнаты и локальных дорожек.
abstract class CallMediaSession extends ChangeNotifier {
  bool get isConnected;

  bool get microphoneEnabled;

  bool get cameraEnabled;

  CallVideoFeed? get remoteVideo;

  CallVideoFeed? get localVideo;

  Future<void> connect(ConsultationJoin join, {required bool enableVideo});

  Future<void> setMicrophoneEnabled(bool enabled);

  Future<void> setCameraEnabled(bool enabled);

  Future<void> disconnect();
}

/// Реализация поверх официального Flutter SDK LiveKit.
class LiveKitCallMediaSession extends CallMediaSession {
  LiveKitCallMediaSession({Room? room})
    : _room =
          room ??
          Room(
            roomOptions: const RoomOptions(
              adaptiveStream: true,
              dynacast: true,
            ),
          ) {
    _listener = _room.createListener()
      ..on<RoomDisconnectedEvent>((_) {
        _connected = false;
        _microphoneEnabled = false;
        _cameraEnabled = false;
        _refresh();
      });
    _room.addListener(_refresh);
  }

  final Room _room;
  late final EventsListener<RoomEvent> _listener;
  var _connected = false;
  var _microphoneEnabled = false;
  var _cameraEnabled = false;
  var _disposing = false;

  @override
  bool get isConnected => _connected;

  @override
  bool get microphoneEnabled => _microphoneEnabled;

  @override
  bool get cameraEnabled => _cameraEnabled;

  @override
  CallVideoFeed? get remoteVideo {
    for (final participant in _room.remoteParticipants.values) {
      for (final publication in participant.videoTrackPublications) {
        final track = publication.track;
        if (track != null && !publication.muted) {
          return _LiveKitVideoFeed(track);
        }
      }
    }
    return null;
  }

  @override
  CallVideoFeed? get localVideo {
    final participant = _room.localParticipant;
    if (participant == null) return null;
    for (final publication in participant.videoTrackPublications) {
      final track = publication.track;
      if (track != null && !publication.muted) {
        return _LiveKitVideoFeed(track);
      }
    }
    return null;
  }

  @override
  Future<void> connect(
    ConsultationJoin join, {
    required bool enableVideo,
  }) async {
    if (_connected) return;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Permission.bluetoothConnect.request();
      } catch (_) {
        // Отказ или отсутствие Bluetooth не должны блокировать динамик.
      }
    }
    await _room.connect(join.videoServerUrl, join.videoToken);
    _connected = true;
    try {
      await setMicrophoneEnabled(true);
    } catch (_) {
      await disconnect();
      rethrow;
    }
    if (enableVideo) {
      try {
        await setCameraEnabled(true);
      } catch (_) {
        // При запрете камеры видеоприём остаётся доступен как аудиозвонок.
        _cameraEnabled = false;
      }
    }
    _refresh();
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final participant = _room.localParticipant;
    if (participant == null) return;
    await participant.setMicrophoneEnabled(enabled);
    _microphoneEnabled = enabled;
    _refresh();
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {
    final participant = _room.localParticipant;
    if (participant == null) return;
    await participant.setCameraEnabled(enabled);
    _cameraEnabled = enabled;
    _refresh();
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    _connected = false;
    _microphoneEnabled = false;
    _cameraEnabled = false;
    await _room.disconnect();
    _refresh();
  }

  void _refresh() {
    if (!_disposing) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposing) return;
    _disposing = true;
    _room.removeListener(_refresh);
    unawaited(_disposeRoom());
    super.dispose();
  }

  Future<void> _disposeRoom() async {
    await _listener.dispose();
    await _room.dispose();
  }
}

class _LiveKitVideoFeed implements CallVideoFeed {
  const _LiveKitVideoFeed(this.track);

  final VideoTrack track;

  @override
  Widget view({required bool mirror}) => VideoTrackRenderer(
    track,
    fit: VideoViewFit.cover,
    mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
  );
}
