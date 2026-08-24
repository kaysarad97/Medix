import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/appointment.dart';
import '../../../telemedicine/data/repositories/consultation_live_chat.dart';
import '../../../telemedicine/data/repositories/consultations_repository.dart';
import '../../../telemedicine/data/services/consultation_file_picker.dart';
import '../../../telemedicine/data/services/consultation_files_service.dart';
import '../../../telemedicine/domain/entities/consultation.dart';
import '../../domain/entities/admin_request.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_own_profile.dart';
import '../../domain/entities/doctor_own_review.dart';
import '../../domain/entities/doctor_patient.dart';
import '../../domain/entities/patient_chat.dart';
import '../../domain/entities/regular_patient.dart';
import '../../domain/entities/work_analytics.dart';
import 'doctor_cabinet_repository.dart';

/// Кабинет текущего врача поверх doctor-facing API.
///
/// Backend пока не предоставляет заявки к администрации клиники — только
/// эти методы временно делегируются макету. Профиль, записи, пациенты,
/// отзывы, сертификат, аналитика и консультационные чаты читаются из
/// реальных данных.
class RemoteDoctorCabinetRepository implements DoctorCabinetRepository {
  RemoteDoctorCabinetRepository(this._dio) {
    final consultations = ConsultationsRepository(_dio);
    _liveChat = ConsultationLiveChat(consultations);
    _files = RemoteConsultationFilesService(consultations);
  }

  final Dio _dio;
  late final ConsultationLiveChat _liveChat;
  late final ConsultationFilesService _files;

  static const _fallback = MockDoctorCabinetRepository();
  static const _pageLimit = 100;

  @override
  Future<List<DoctorAppointment>> upcomingAppointments() async {
    final now = DateTime.now();
    return _activeAppointments(
      from: now,
      to: now.add(const Duration(days: 365)),
    );
  }

  @override
  Future<List<DoctorAppointment>> appointmentsForDay(DateTime day) {
    final from = DateTime(day.year, day.month, day.day);
    final to = from
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));
    return _activeAppointments(from: from, to: to);
  }

  @override
  Future<List<RegularPatient>> regularPatients() async {
    final raw = await _appointmentJson();
    final patients = <String, RegularPatient>{};
    for (final item in raw) {
      final patient = item['patient'] as Map<String, dynamic>?;
      final id = patient?['id'] as String?;
      if (id == null || id.isEmpty) continue;
      patients[id] = RegularPatient(
        id: id,
        fullName: patient?['full_name'] as String? ?? '',
      );
    }
    return patients.values.toList(growable: false);
  }

  @override
  Future<DoctorOwnProfile> ownProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myDoctor,
      );
      return _profile(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<DoctorOwnProfile> updateOwnProfile(DoctorOwnProfile profile) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.me,
        data: {'full_name': profile.fullName},
      );
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myDoctor,
      );
      return _profile(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Certificate>> certificates() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myDoctor,
      );
      final url = response.data?['credential_url'] as String?;
      if (url == null || url.isEmpty) return const [];

      final uri = Uri.tryParse(url);
      final rawName = uri == null || uri.pathSegments.isEmpty
          ? ''
          : uri.pathSegments.last;
      return [
        Certificate(
          id: url,
          fileName: rawName.isEmpty ? 'Документ врача' : rawName,
        ),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<DoctorOwnReview>> ownReviews() async {
    try {
      final me = await _dio.get<Map<String, dynamic>>(ApiEndpoints.myDoctor);
      final doctorId = me.data!['id'] as String;
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.doctorReviews(doctorId),
      );
      return [
        for (final item in response.data ?? const [])
          _review(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<DoctorAppointment>> pastAppointments({
    required DateTime from,
    required DateTime to,
  }) => _appointments(from: from, to: to, status: 'completed');

  @override
  Future<DoctorAppointment> pastAppointment(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.myDoctorAppointment(id),
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<DoctorAppointment> saveConclusion(
    String appointmentId,
    String text,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myDoctorAppointment(appointmentId),
        data: {
          'action': 'complete',
          'conclusion': {'text': text.trim()},
        },
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<DoctorAppointment> completeAppointment(String appointmentId) =>
      _patchAppointmentAction(appointmentId, {'action': 'complete'});

  @override
  Future<DoctorAppointment> cancelAppointment(
    String appointmentId,
    String reason,
  ) => _patchAppointmentAction(appointmentId, {
    'action': 'cancel',
    'reason': reason.trim(),
  });

  @override
  Future<void> markAppointmentNoShow(String appointmentId) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myDoctorAppointmentNoShow(appointmentId),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<DoctorPatient> patient(String id) async {
    try {
      Map<String, dynamic> detail;
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.myDoctorAppointment(id),
        );
        detail = response.data!;
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) rethrow;
        final rows = await _appointmentJson();
        final matching = rows.where(
          (row) => (row['patient'] as Map<String, dynamic>?)?['id'] == id,
        );
        if (matching.isEmpty) {
          throw const ApiException('Пациент не найден', statusCode: 404);
        }
        final nearest = matching.reduce(_nearestAppointment);
        final response = await _dio.get<Map<String, dynamic>>(
          ApiEndpoints.myDoctorAppointment(nearest['id'] as String),
        );
        detail = response.data!;
      }

      final patient = detail['patient'] as Map<String, dynamic>? ?? const {};
      final patientId = patient['id'] as String? ?? id;
      final recordsResponse = await _dio.get<List<dynamic>>(
        ApiEndpoints.myDoctorPatientMedicalRecords(patientId),
      );
      final records = [
        for (final item in recordsResponse.data ?? const [])
          item as Map<String, dynamic>,
      ];
      return _patient(detail, records);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<DoctorWorkAnalytics> workAnalytics() async {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final queryStart = weekStart.isBefore(monthStart) ? weekStart : monthStart;
    final queryEnd = DateTime(now.year, now.month + 1);
    final appointments = await _appointments(
      from: queryStart,
      to: queryEnd,
      status: 'completed',
    );

    final week = appointments
        .where((item) => !item.startsAt.isBefore(weekStart))
        .toList();
    final month = appointments
        .where((item) => !item.startsAt.isBefore(monthStart))
        .toList();
    final monthDays = DateTime(now.year, now.month + 1, 0).day;

    return DoctorWorkAnalytics(
      week: DoctorWeekAnalytics(
        from: weekStart,
        to: weekStart.add(const Duration(days: 6)),
        perDay: [
          for (var i = 0; i < 7; i++)
            week.where((item) => item.startsAt.weekday == i + 1).length,
        ],
        stats: _stats(week),
      ),
      month: DoctorMonthAnalytics(
        month: monthStart,
        perDay: [
          for (var day = 1; day <= monthDays; day++)
            month.where((item) => item.startsAt.day == day).length,
        ],
        stats: _stats(month),
      ),
    );
  }

  @override
  Future<List<PatientChatThread>> patientChats() async {
    final userId = await _currentUserId();
    final consultationsRepository = ConsultationsRepository(_dio);
    final consultations = await consultationsRepository.consultations();
    final threads = await Future.wait([
      for (final consultation in consultations)
        _patientThread(consultation, userId, consultationsRepository),
    ]);
    threads.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return threads;
  }

  @override
  Future<List<PatientMessage>> patientMessages(String threadId) async {
    final userId = await _currentUserId();
    final messages = await ConsultationsRepository(_dio).messages(threadId);
    return [
      for (final message in messages)
        PatientMessage(
          id: message.id,
          text: message.body,
          isMine: message.senderId == userId,
          sentAt: message.createdAt,
        ),
    ];
  }

  @override
  Stream<PatientMessage> watchPatientMessages(String threadId) async* {
    final userId = await _currentUserId();
    await for (final message in _liveChat.watch(threadId, userId: userId)) {
      yield PatientMessage(
        id: message.id,
        text: message.body,
        isMine: message.senderId == userId,
        sentAt: message.createdAt,
      );
    }
  }

  @override
  Future<PatientMessage> sendPatientMessage(
    String threadId,
    String text,
  ) async {
    final userId = await _currentUserId();
    final message = await _liveChat.send(threadId, userId: userId, body: text);
    return PatientMessage(
      id: message.id,
      text: message.body,
      isMine: true,
      sentAt: message.createdAt,
    );
  }

  @override
  Future<List<ConsultationFile>> patientChatFiles(String threadId) =>
      _files.files(threadId);

  @override
  Future<ConsultationFile> uploadPatientChatFile(
    String threadId,
    PickedConsultationFile file,
  ) => _files.upload(threadId, file);

  @override
  Future<ConsultationFileDownload> patientChatFileDownload(
    String threadId,
    String fileId,
  ) => _files.download(threadId, fileId);

  @override
  Future<void> closePatientChat(String threadId) => _liveChat.close(threadId);

  /// Doctor-to-admin API на сервере отсутствует.
  @override
  Future<List<AdminRequest>> adminRequests() => _fallback.adminRequests();

  @override
  Future<AdminRequest> adminRequest(String id) => _fallback.adminRequest(id);

  @override
  Future<AdminRequest> sendAdminRequest({
    required AdminRequestTopic topic,
    required String text,
  }) => _fallback.sendAdminRequest(topic: topic, text: text);

  Future<List<DoctorAppointment>> _appointments({
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    final raw = await _appointmentJson(from: from, to: to, status: status);
    final result = raw.map(_appointment).toList();
    result.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return result;
  }

  Future<DoctorAppointment> _patchAppointmentAction(
    String appointmentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.myDoctorAppointment(appointmentId),
        data: data,
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<DoctorAppointment>> _activeAppointments({
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = await _appointmentJson(from: from, to: to);
    final result = raw
        .where(
          (item) => const {
            'pending',
            'confirmed',
            'in_progress',
          }.contains(item['status']),
        )
        .map(_appointment)
        .toList();
    result.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return result;
  }

  Future<List<Map<String, dynamic>>> _appointmentJson({
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    try {
      final result = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final response = await _dio.get<List<dynamic>>(
          ApiEndpoints.myDoctorAppointments,
          queryParameters: {
            'from': ?from?.toUtc().toIso8601String(),
            'to': ?to?.toUtc().toIso8601String(),
            'status': ?status,
            'limit': _pageLimit,
            if (offset > 0) 'offset': offset,
          },
        );
        final page = response.data ?? const <dynamic>[];
        result.addAll(page.cast<Map<String, dynamic>>());
        if (page.length < _pageLimit) break;
        offset += page.length;
      }
      return result;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<PatientChatThread> _patientThread(
    Consultation consultation,
    String userId,
    ConsultationsRepository consultationsRepository,
  ) async {
    try {
      final results = await Future.wait<Object>([
        _dio.get<Map<String, dynamic>>(
          ApiEndpoints.myDoctorAppointment(consultation.appointmentId),
        ),
        consultationsRepository.messages(consultation.id),
      ]);
      final appointment = (results[0] as Response<Map<String, dynamic>>).data!;
      final messages = results[1] as List<ConsultationMessage>;
      final patient =
          appointment['patient'] as Map<String, dynamic>? ?? const {};
      final last = messages.isEmpty ? null : messages.last;
      return PatientChatThread(
        id: consultation.id,
        patientName: patient['full_name'] as String? ?? '',
        lastMessage: last?.body ?? '',
        lastMessageAt:
            last?.createdAt ??
            DateTime.parse(appointment['starts_at'] as String).toLocal(),
        lastMessageIsMine: last?.senderId == userId,
        // Backend пока не хранит прочтение сообщений.
        isRead: true,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> _currentUserId() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      return response.data!['id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static DoctorOwnProfile _profile(Map<String, dynamic> json) {
    final experience = (json['experience_years'] as num?)?.round();
    final clinic = json['clinic'] as Map<String, dynamic>?;
    final address = [
      clinic?['name'] as String?,
      json['city'] as String?,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
    return DoctorOwnProfile(
      fullName: json['full_name'] as String? ?? '',
      doctorId:
          json['license_number'] as String? ?? json['id'] as String? ?? '',
      status: switch (json['verification_status']) {
        'approved' => 'активен',
        'rejected' => 'отклонён',
        _ => 'на проверке',
      },
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      specialization: json['specialty'] as String? ?? '',
      experience: experience == null ? '' : '$experience лет',
      category: '',
      address: address,
      // Отдельного флага формата работы в DoctorMeOut пока нет.
      onlineConsultations: true,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  static DoctorOwnReview _review(Map<String, dynamic> json) => DoctorOwnReview(
    id: json['id'] as String,
    authorName: json['author_name'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    text: json['body'] as String? ?? '',
  );

  static DoctorAppointment _appointment(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? const {};
    final conclusion = json['conclusion'] as Map<String, dynamic>?;
    final payload = conclusion?['payload'] as Map<String, dynamic>?;
    return DoctorAppointment(
      id: json['id'] as String,
      patientId: patient['id'] as String?,
      patientName: patient['full_name'] as String? ?? '',
      consultationId: json['consultation_id'] as String?,
      kind: switch (json['type']) {
        'audio' => AppointmentKind.audioCall,
        'in_person' => AppointmentKind.inPerson,
        _ => AppointmentKind.videoCall,
      },
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? '')?.toLocal(),
      status: _appointmentStatus(json['status'] as String?),
      conclusion: payload?['text'] as String?,
    );
  }

  static AppointmentStatus _appointmentStatus(String? value) => switch (value) {
    'pending' => AppointmentStatus.pending,
    'confirmed' => AppointmentStatus.confirmed,
    'completed' => AppointmentStatus.completed,
    'cancelled' => AppointmentStatus.cancelled,
    'no_show' => AppointmentStatus.noShow,
    _ => AppointmentStatus.unknown,
  };

  static Map<String, dynamic> _nearestAppointment(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final now = DateTime.now();
    final aTime = DateTime.parse(a['starts_at'] as String).toLocal();
    final bTime = DateTime.parse(b['starts_at'] as String).toLocal();
    final aFuture = !aTime.isBefore(now);
    final bFuture = !bTime.isBefore(now);
    if (aFuture != bFuture) return aFuture ? a : b;
    return aFuture
        ? (aTime.isBefore(bTime) ? a : b)
        : (aTime.isAfter(bTime) ? a : b);
  }

  static DoctorPatient _patient(
    Map<String, dynamic> detail,
    List<Map<String, dynamic>> records,
  ) {
    final patient = detail['patient'] as Map<String, dynamic>? ?? const {};
    final birthDate = DateTime.tryParse(patient['birth_date'] as String? ?? '');
    final appointment = _appointment(detail);
    final conclusion = detail['conclusion'] as Map<String, dynamic>?;
    final conclusionPayload = conclusion?['payload'] as Map<String, dynamic>?;
    return DoctorPatient(
      id: patient['id'] as String? ?? '',
      fullName: patient['full_name'] as String? ?? '',
      heightCm: _latestMeasurement(records, 'height')?.round() ?? 0,
      weightKg: _latestMeasurement(records, 'weight')?.round() ?? 0,
      age: birthDate == null ? 0 : _age(birthDate, DateTime.now()),
      appointment: appointment,
      conclusion: conclusionPayload?['text'] as String?,
      // Лабораторные результаты пока не входят в doctor-facing контракт.
      analyses: const [],
    );
  }

  static double? _latestMeasurement(
    List<Map<String, dynamic>> records,
    String kind,
  ) {
    final matching = records.where((record) {
      final payload = record['payload'] as Map<String, dynamic>?;
      return record['record_type'] == 'measurement' && payload?['kind'] == kind;
    }).toList();
    if (matching.isEmpty) return null;
    matching.sort(
      (a, b) => DateTime.parse(
        b['created_at'] as String,
      ).compareTo(DateTime.parse(a['created_at'] as String)),
    );
    final payload = matching.first['payload'] as Map<String, dynamic>;
    return (payload['value'] as num?)?.toDouble();
  }

  static int _age(DateTime birthDate, DateTime today) {
    var result = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      result--;
    }
    return result;
  }

  static DoctorWorkStats _stats(List<DoctorAppointment> appointments) {
    final durations = appointments
        .where((item) => item.endsAt != null)
        .map((item) => item.endsAt!.difference(item.startsAt).inMinutes)
        .where((minutes) => minutes >= 0)
        .toList();
    final average = durations.isEmpty
        ? 0
        : durations.reduce((a, b) => a + b) ~/ durations.length;
    return DoctorWorkStats(
      appointments: appointments.length,
      deltaVsUsual: 0,
      averageMinutes: average,
      ratingDelta: 0,
      earningsPercent: 0,
    );
  }
}
