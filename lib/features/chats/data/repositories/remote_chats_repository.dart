import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../telemedicine/data/repositories/consultation_live_chat.dart';
import '../../../telemedicine/data/repositories/consultations_repository.dart';
import '../../../telemedicine/data/services/consultation_file_picker.dart';
import '../../../telemedicine/data/services/consultation_files_service.dart';
import '../../../telemedicine/domain/entities/consultation.dart';
import '../../domain/entities/chat_thread.dart';
import 'chats_repository.dart';

/// Переписки пациента, собранные из консультаций, записей и сообщений.
///
/// `GET /consultations` пока не содержит врача, последнюю реплику и счётчик
/// непрочитанных, поэтому первые два поля достраиваются клиентом. `isRead`
/// остаётся true до появления unread-контракта.
class RemoteChatsRepository implements ChatsRepository {
  RemoteChatsRepository(
    this._dio, {
    ConsultationsRepository? consultationsRepository,
  }) : _consultations =
           consultationsRepository ?? ConsultationsRepository(_dio) {
    _liveChat = ConsultationLiveChat(_consultations);
    _files = RemoteConsultationFilesService(_consultations);
  }

  final Dio _dio;
  final ConsultationsRepository _consultations;
  late final ConsultationLiveChat _liveChat;
  late final ConsultationFilesService _files;

  @override
  Future<List<ChatThread>> threads() async {
    final userId = await _currentUserId();
    final consultations = await _consultations.consultations();
    final threads = await Future.wait([
      for (final consultation in consultations) _thread(consultation, userId),
    ]);
    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  Future<ChatThread> _thread(Consultation consultation, String userId) async {
    try {
      final results = await Future.wait<Object>([
        _dio.get<Map<String, dynamic>>(
          ApiEndpoints.appointment(consultation.appointmentId),
        ),
        _consultations.messages(consultation.id),
      ]);
      final appointment = (results[0] as Response<Map<String, dynamic>>).data!;
      final messages = results[1] as List<ConsultationMessage>;
      final doctor = appointment['doctor'] as Map<String, dynamic>? ?? const {};
      final last = messages.isEmpty ? null : messages.last;
      return ChatThread(
        id: consultation.id,
        doctorId: doctor['id'] as String?,
        doctorName: doctor['full_name'] as String? ?? '',
        doctorPhotoUrl: doctor['photo_url'] as String?,
        lastMessage: last?.body ?? '',
        lastMessageAt:
            last?.createdAt ??
            DateTime.parse(appointment['starts_at'] as String).toLocal(),
        lastMessageIsMine: last?.senderId == userId,
        isRead: true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<DoctorMessage>> messages(String threadId) async {
    final userId = await _currentUserId();
    final messages = await _consultations.messages(threadId);
    return [
      for (final message in messages)
        DoctorMessage(
          id: message.id,
          text: message.body,
          isMine: message.senderId == userId,
          sentAt: message.createdAt,
        ),
    ];
  }

  @override
  Stream<DoctorMessage> watchMessages(String threadId) async* {
    final userId = await _currentUserId();
    await for (final message in _liveChat.watch(threadId, userId: userId)) {
      yield DoctorMessage(
        id: message.id,
        text: message.body,
        isMine: message.senderId == userId,
        sentAt: message.createdAt,
      );
    }
  }

  @override
  Future<DoctorMessage> send(String threadId, String text) async {
    final userId = await _currentUserId();
    final message = await _liveChat.send(threadId, userId: userId, body: text);
    return DoctorMessage(
      id: message.id,
      text: message.body,
      isMine: true,
      sentAt: message.createdAt,
    );
  }

  @override
  Future<List<ConsultationFile>> files(String threadId) =>
      _files.files(threadId);

  @override
  Future<ConsultationFile> uploadFile(
    String threadId,
    PickedConsultationFile file,
  ) => _files.upload(threadId, file);

  @override
  Future<ConsultationFileDownload> fileDownload(
    String threadId,
    String fileId,
  ) => _files.download(threadId, fileId);

  @override
  Future<void> closeChat(String threadId) => _liveChat.close(threadId);

  Future<String> _currentUserId() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return response.data!['id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
