import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/consultation.dart';

class ConsultationsRepository {
  const ConsultationsRepository(this._dio);

  final Dio _dio;

  Future<ConsultationJoin> join(String consultationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.consultationJoin(consultationId),
      );
      final json = response.data!;
      return ConsultationJoin(
        roomId: json['room_id'] as String,
        webSocketTicket: json['ws_ticket'] as String,
        videoToken: json['video_token'] as String,
        videoServerUrl: json['video_server_url'] as String,
        mode: json['mode'] == 'audio'
            ? ConsultationMode.audio
            : ConsultationMode.video,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Consultation> complete(String consultationId) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.consultationComplete(consultationId),
      );
      return _consultation(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ConsultationMessage>> messages(String consultationId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.consultationMessages(consultationId),
      );
      return [
        for (final item in response.data ?? const [])
          _message(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static Consultation _consultation(Map<String, dynamic> json) => Consultation(
    id: json['id'] as String,
    appointmentId: json['appointment_id'] as String,
    status: switch (json['status']) {
      'scheduled' => ConsultationStatus.scheduled,
      'in_progress' => ConsultationStatus.inProgress,
      'completed' => ConsultationStatus.completed,
      'cancelled' => ConsultationStatus.cancelled,
      _ => ConsultationStatus.unknown,
    },
    startedAt: DateTime.tryParse(
      json['started_at'] as String? ?? '',
    )?.toLocal(),
    endedAt: DateTime.tryParse(json['ended_at'] as String? ?? '')?.toLocal(),
  );

  static ConsultationMessage _message(Map<String, dynamic> json) =>
      ConsultationMessage(
        id: json['id'] as String,
        consultationId: json['consultation_id'] as String,
        senderId: json['sender_id'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}
