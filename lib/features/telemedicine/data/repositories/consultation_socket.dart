import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/consultation.dart';

abstract interface class ConsultationSocketChannel {
  Stream<dynamic> get stream;
  StreamSink<dynamic> get sink;
}

class WebSocketConsultationChannel implements ConsultationSocketChannel {
  WebSocketConsultationChannel(Uri uri)
    : _channel = WebSocketChannel.connect(uri);

  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  StreamSink<dynamic> get sink => _channel.sink;
}

typedef ConsultationChannelFactory =
    ConsultationSocketChannel Function(Uri uri);

class ConsultationSocket {
  ConsultationSocket({ConsultationChannelFactory? channelFactory})
    : _channelFactory = channelFactory ?? WebSocketConsultationChannel.new;

  final ConsultationChannelFactory _channelFactory;
  ConsultationSocketChannel? _channel;

  Stream<ConsultationSocketEvent> connect({
    required String consultationId,
    required String ticket,
  }) {
    if (_channel != null) {
      throw StateError('Соединение с консультацией уже открыто');
    }
    final channel = _channelFactory(_uri(consultationId, ticket));
    _channel = channel;
    return channel.stream.map(_event);
  }

  void send(String body) {
    final channel = _channel;
    if (channel == null) {
      throw StateError('Соединение с консультацией не открыто');
    }
    channel.sink.add(jsonEncode({'body': body}));
  }

  Future<void> close() async {
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
  }

  static Uri _uri(String consultationId, String ticket) {
    final base = Uri.parse(ApiEndpoints.baseUrl);
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/consultations/$consultationId',
      queryParameters: {'ws_ticket': ticket},
    );
  }

  static ConsultationSocketEvent _event(dynamic raw) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) {
      return const ConsultationSocketErrorEvent('Невалидное сообщение сервера');
    }
    final json = Map<String, dynamic>.from(decoded);
    return switch (json['type']) {
      'history' => ConsultationHistoryEvent([
        for (final item in json['messages'] as List<dynamic>? ?? const [])
          _message(Map<String, dynamic>.from(item as Map)),
      ]),
      'message' => ConsultationMessageEvent(_message(json)),
      'error' => ConsultationSocketErrorEvent(
        json['detail'] as String? ?? 'Ошибка чата',
      ),
      _ => const ConsultationSocketErrorEvent('Неизвестное сообщение сервера'),
    };
  }

  static ConsultationMessage _message(Map<String, dynamic> json) =>
      ConsultationMessage(
        id: json['id'] as String,
        consultationId: json['consultation_id'] as String,
        senderId: json['sender_id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
