import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../telemedicine/data/repositories/consultations_repository.dart';
import '../../../telemedicine/domain/entities/consultation.dart';
import '../../../telemedicine/presentation/providers/telemedicine_providers.dart';
import '../../data/call_media_session.dart';

enum CallSessionStatus { idle, connecting, connected, ended, failed }

@immutable
class CallSessionState {
  const CallSessionState({
    this.status = CallSessionStatus.idle,
    this.supportsVideo = false,
    this.microphoneEnabled = false,
    this.cameraEnabled = false,
    this.remoteVideo,
    this.localVideo,
    this.errorMessage,
  });

  final CallSessionStatus status;
  final bool supportsVideo;
  final bool microphoneEnabled;
  final bool cameraEnabled;
  final CallVideoFeed? remoteVideo;
  final CallVideoFeed? localVideo;
  final String? errorMessage;
}

/// Один контроллер на один открытый экран звонка.
class CallSessionController extends ChangeNotifier {
  CallSessionController(this._repository, this._media) {
    _media.addListener(_syncMedia);
  }

  final ConsultationsRepository _repository;
  final CallMediaSession _media;
  CallSessionState _state = const CallSessionState();
  String? _consultationId;
  var _connectionGeneration = 0;
  var _disposed = false;

  CallSessionState get state => _state;

  Future<void> connect(
    String consultationId, {
    required bool enableVideo,
  }) async {
    if (_consultationId == consultationId &&
        _state.status != CallSessionStatus.failed) {
      return;
    }
    _consultationId = consultationId;
    final generation = ++_connectionGeneration;
    _state = const CallSessionState(status: CallSessionStatus.connecting);
    _notify();
    try {
      final join = await _repository.join(consultationId);
      if (_disposed || generation != _connectionGeneration) return;
      final supportsVideo = join.mode == ConsultationMode.video;
      _state = CallSessionState(
        status: CallSessionStatus.connecting,
        supportsVideo: supportsVideo,
      );
      _notify();
      await _media.connect(join, enableVideo: enableVideo && supportsVideo);
      if (_disposed || generation != _connectionGeneration) {
        await _media.disconnect();
        return;
      }
      _syncMedia();
    } catch (error) {
      if (_disposed || generation != _connectionGeneration) return;
      _state = CallSessionState(
        status: CallSessionStatus.failed,
        errorMessage: _message(error),
      );
      _notify();
    }
  }

  Future<void> toggleMicrophone() async {
    if (_state.status != CallSessionStatus.connected) return;
    try {
      await _media.setMicrophoneEnabled(!_state.microphoneEnabled);
    } catch (error) {
      _setError(error);
    }
  }

  Future<void> toggleCamera() async {
    if (_state.status != CallSessionStatus.connected || !_state.supportsVideo) {
      return;
    }
    try {
      await _media.setCameraEnabled(!_state.cameraEnabled);
    } catch (error) {
      _setError(error);
    }
  }

  /// Завершение на стороне врача дополнительно закрывает консультацию и
  /// освобождает escrow. Пациент только выходит из комнаты.
  Future<void> hangUp({required bool completeConsultation}) async {
    if (_state.status == CallSessionStatus.ended) return;
    _connectionGeneration++;
    final consultationId = _consultationId;
    _state = CallSessionState(
      status: CallSessionStatus.ended,
      supportsVideo: _state.supportsVideo,
    );
    _notify();
    try {
      await _media.disconnect();
    } catch (error) {
      _setError(error);
    }
    if (completeConsultation && consultationId != null) {
      try {
        await _repository.complete(consultationId);
      } catch (error) {
        _setError(error);
      }
    }
  }

  void _syncMedia() {
    if (_disposed || _state.status == CallSessionStatus.ended) return;
    _state = CallSessionState(
      status: _media.isConnected
          ? CallSessionStatus.connected
          : CallSessionStatus.ended,
      supportsVideo: _state.supportsVideo,
      microphoneEnabled: _media.microphoneEnabled,
      cameraEnabled: _media.cameraEnabled,
      remoteVideo: _media.remoteVideo,
      localVideo: _media.localVideo,
      errorMessage: _state.errorMessage,
    );
    _notify();
  }

  void _setError(Object error) {
    _state = CallSessionState(
      status: _state.status,
      supportsVideo: _state.supportsVideo,
      microphoneEnabled: _state.microphoneEnabled,
      cameraEnabled: _state.cameraEnabled,
      remoteVideo: _state.remoteVideo,
      localVideo: _state.localVideo,
      errorMessage: _message(error),
    );
    _notify();
  }

  static String _message(Object error) {
    if (error is ApiException) return error.message;
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _connectionGeneration++;
    _media.removeListener(_syncMedia);
    _media.dispose();
    super.dispose();
  }
}

typedef CallSessionControllerFactory = CallSessionController Function();

final callSessionControllerFactoryProvider =
    Provider<CallSessionControllerFactory>((ref) {
      final repository = ref.watch(consultationsRepositoryProvider);
      return () => CallSessionController(repository, LiveKitCallMediaSession());
    });
