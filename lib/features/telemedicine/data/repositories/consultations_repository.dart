import 'dart:async';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/consultation.dart';
import '../../domain/entities/doctor_review.dart';
import 'consultation_socket.dart';

class ConsultationsRepository {
  ConsultationsRepository(
    this._dio, {
    ConsultationSocket Function()? socketFactory,
  }) : _socketFactory = socketFactory ?? ConsultationSocket.new;

  final Dio _dio;
  final ConsultationSocket Function() _socketFactory;

  Future<List<Consultation>> consultations({
    ConsultationStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.consultations,
        queryParameters: {
          if (status != null) 'status': _statusValue(status),
          'limit': limit,
          'offset': offset,
        },
      );
      return [
        for (final item in response.data ?? const [])
          _consultation(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

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

  /// WebSocket — единственный серверный транспорт отправки сообщения.
  /// Короткоживущий ticket получается непосредственно перед соединением;
  /// возвращаем подтверждённую сервером реплику, а не оптимистичный локальный
  /// объект без настоящего id.
  Future<ConsultationMessage> sendMessage(
    String consultationId, {
    required String senderId,
    required String body,
  }) async {
    final joinInfo = await join(consultationId);
    final socket = _socketFactory();
    final result = Completer<ConsultationMessage>();
    late final StreamSubscription<ConsultationSocketEvent> subscription;
    subscription = socket
        .connect(
          consultationId: consultationId,
          ticket: joinInfo.webSocketTicket,
        )
        .listen(
          (event) {
            switch (event) {
              case ConsultationMessageEvent(:final message)
                  when message.senderId == senderId && message.body == body:
                if (!result.isCompleted) {
                  result.complete(message);
                }
              case ConsultationSocketErrorEvent(:final detail):
                if (!result.isCompleted) {
                  result.completeError(ApiException(detail));
                }
              case ConsultationHistoryEvent():
              case ConsultationMessageEvent():
                break;
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!result.isCompleted) result.completeError(error, stackTrace);
          },
          onDone: () {
            if (!result.isCompleted) {
              result.completeError(
                const ApiException('Соединение с чатом закрыто'),
              );
            }
          },
        );
    socket.send(body);

    try {
      return await result.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () =>
            throw const ApiException('Сервер не подтвердил отправку сообщения'),
      );
    } finally {
      await subscription.cancel();
      await socket.close();
    }
  }

  Future<ConsultationFileUpload> requestFileUpload(
    String consultationId, {
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.consultationFileUploadUrl(consultationId),
        data: {'filename': filename, 'content_type': contentType},
      );
      final json = response.data!;
      return ConsultationFileUpload(
        uploadUrl: json['upload_url'] as String,
        fields: (json['fields'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as String),
        ),
        key: json['key'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConsultationFile> confirmFileUpload(
    String consultationId, {
    required String s3Key,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.consultationFiles(consultationId),
        data: {'s3_key': s3Key},
      );
      return _file(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<ConsultationFile>> files(String consultationId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.consultationFiles(consultationId),
      );
      return [
        for (final item in response.data ?? const [])
          _file(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConsultationFileDownload> fileDownload(
    String consultationId,
    String fileId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.consultationFileDownloadUrl(consultationId, fileId),
      );
      final json = response.data!;
      return ConsultationFileDownload(
        url: json['download_url'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ConsultationDispute> dispute(
    String consultationId,
    String reason,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.consultationDispute(consultationId),
        data: {'reason': reason},
      );
      return _dispute(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<DoctorReview> review(
    String consultationId, {
    required int rating,
    String? body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.consultationReview(consultationId),
        data: {'rating': rating, 'body': body},
      );
      final json = response.data!;
      return DoctorReview(
        id: json['id'] as String,
        authorName: json['author_name'] as String,
        rating: (json['rating'] as num).toDouble(),
        text: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// На экране отзыв маршрутизируется по doctor id, тогда как сервер
  /// принимает consultation id. Связываем их через завершённые консультации
  /// и пациентские записи, выбирая последнюю консультацию с этим врачом.
  Future<DoctorReview> reviewDoctor(
    String doctorId, {
    required int rating,
    String? body,
  }) async {
    final completed = await consultations(status: ConsultationStatus.completed);
    final matches = <Consultation>[];
    for (final consultation in completed) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.appointment(consultation.appointmentId),
        );
        final doctor = response.data?['doctor'] as Map<String, dynamic>?;
        if (doctor?['id'] == doctorId) matches.add(consultation);
      } on DioException catch (e) {
        throw ApiException.fromDio(e);
      }
    }
    if (matches.isEmpty) {
      throw const ApiException(
        'Нет завершённой консультации с этим врачом',
        statusCode: 404,
      );
    }
    matches.sort(
      (a, b) => (b.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.endedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    return review(matches.first.id, rating: rating, body: body);
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

  static ConsultationFile _file(Map<String, dynamic> json) => ConsultationFile(
    id: json['id'] as String,
    consultationId: json['consultation_id'] as String,
    uploadedBy: json['uploaded_by'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  static ConsultationDispute _dispute(Map<String, dynamic> json) =>
      ConsultationDispute(
        id: json['id'] as String,
        consultationId: json['consultation_id'] as String,
        raisedBy: json['raised_by'] as String,
        reason: json['reason'] as String,
        status: switch (json['status']) {
          'open' => ConsultationDisputeStatus.open,
          'resolved' => ConsultationDisputeStatus.resolved,
          _ => ConsultationDisputeStatus.unknown,
        },
        resolution: json['resolution'] as String?,
        resolvedBy: json['resolved_by'] as String?,
        resolvedAt: DateTime.tryParse(
          json['resolved_at'] as String? ?? '',
        )?.toLocal(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  static String _statusValue(ConsultationStatus status) => switch (status) {
    ConsultationStatus.scheduled => 'scheduled',
    ConsultationStatus.inProgress => 'in_progress',
    ConsultationStatus.completed => 'completed',
    ConsultationStatus.cancelled => 'cancelled',
    ConsultationStatus.unknown => 'unknown',
  };
}
