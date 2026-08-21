import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';
import 'doctors_repository.dart';

/// Каталог врачей, расписание и запись на приём поверх FastAPI-бэкенда.
///
/// Цену считает сервер: в ответе `consult_price` — полная, `price_for_user`
/// — с учётом подписки, плюс `discount_percent` и `discount_reason`. Клиент
/// свою скидку не выводит, иначе показанное и списанное разошлись бы.
///
/// С 17 августа 2026 сервер отдаёт и клинику с названием, и стаж, и число
/// отзывов — до этого в карточках стояли захардкоженные «4.5», «100
/// отзывов», «Стаж 10 лет» и «Название клиники». Чего по-прежнему нет:
/// города и фотографии врача.
class RemoteDoctorsRepository implements DoctorsRepository {
  RemoteDoctorsRepository(this._dio);

  final Dio _dio;

  @override
  Future<Doctor> doctor(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.doctor(id),
      );
      return _doctor(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Doctor>> search(String query) async {
    final specialty = query.trim();
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.doctors,
        // Свободного поиска у сервера нет — только фильтр по специальности.
        // Пустой запрос отдаёт весь каталог, как и на экране поиска.
        queryParameters: {
          if (specialty.isNotEmpty) 'specialty': specialty,
          'limit': _catalogLimit,
        },
      );
      return [
        for (final item in response.data ?? const [])
          _doctor(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Сколько врачей просить за раз. Сотня — верхняя граница сервера;
  /// постраничной подгрузки на экране поиска нет, а меньше просить незачем.
  static const int _catalogLimit = 100;

  @override
  Future<DoctorSchedule> schedule(String doctorId, {DateTime? from}) async {
    final start = from ?? DateTime.now();
    final firstDay = DateTime(start.year, start.month, start.day);
    final lastDay = firstDay.add(const Duration(days: _weekLength - 1));

    List<dynamic> raw;
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.doctorSlots(doctorId),
        queryParameters: {
          'from': firstDay.toIso8601String(),
          // Конец последнего дня, а не его начало: иначе седьмой день ленты
          // пришёл бы пустым.
          'to': lastDay
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1))
              .toIso8601String(),
        },
      );
      raw = response.data ?? const [];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }

    final byDay = <DateTime, List<ScheduleSlot>>{};
    for (final item in raw) {
      final json = item as Map<String, dynamic>;
      // Занятые слоты сервер отдаёт вместе со свободными — в ленте нужны
      // только те, на которые можно записаться.
      if (json['status'] != 'open') continue;

      final startsAt = DateTime.tryParse(json['starts_at'] as String? ?? '');
      if (startsAt == null) continue;

      final local = startsAt.toLocal();
      // Прошедшее время в текущем дне отбрасываем: записаться в него нельзя,
      // а место в ленте оно занимает.
      if (local.isBefore(start)) continue;

      final day = DateTime(local.year, local.month, local.day);
      byDay
          .putIfAbsent(day, () => [])
          .add(ScheduleSlot(id: json['id'] as String, startsAt: local));
    }

    for (final slots in byDay.values) {
      slots.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    }

    return DoctorSchedule(
      days: [
        for (var i = 0; i < _weekLength; i++)
          () {
            final day = DateTime(
              firstDay.year,
              firstDay.month,
              firstDay.day + i,
            );
            return ScheduleDay(date: day, slots: byDay[day] ?? const []);
          }(),
      ],
    );
  }

  /// Столько колонок в ленте расписания на макете.
  static const int _weekLength = 7;

  @override
  Future<Appointment> book({
    required Doctor doctor,
    required ScheduleSlot slot,
    required AppointmentKind kind,
    String? familyMemberId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.appointments,
        data: {
          'slot_id': slot.id,
          'type': _typeOf(kind),
          'family_member_id': familyMemberId,
        },
      );

      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Формат приёма в терминах сервера.
  ///
  /// Чата среди них нет: переписка с врачом живёт отдельно от записи
  /// (`/consultations/{id}/messages`), и записаться «на чат» нельзя.
  static String _typeOf(AppointmentKind kind) => switch (kind) {
    AppointmentKind.videoCall => 'video',
    AppointmentKind.audioCall => 'audio',
    AppointmentKind.inPerson => 'in_person',
    AppointmentKind.chat => throw const ApiException(
      'На чат записаться нельзя — выберите формат приёма',
    ),
  };

  @override
  Future<Appointment> appointment(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.appointment(id),
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Appointment>> appointments({bool upcoming = false}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.appointments,
        queryParameters: {'upcoming': upcoming, 'limit': 100},
      );
      return [
        for (final item in response.data ?? const [])
          _appointment(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Appointment> reschedule(String id, ScheduleSlot newSlot) =>
      _patchAppointment(id, {
        'action': 'reschedule',
        'new_slot_id': newSlot.id,
      });

  @override
  Future<Appointment> cancel(String id) =>
      _patchAppointment(id, {'action': 'cancel'});

  @override
  Future<WaitlistEntry> joinWaitlist(String doctorId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.waitlist,
        data: {'doctor_id': doctorId},
      );
      return _waitlistEntry(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<WaitlistEntry>> waitlistEntries() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.waitlist);
      return [
        for (final item in response.data ?? const [])
          _waitlistEntry(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> leaveWaitlist(String entryId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.waitlistEntry(entryId));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Appointment> claimWaitlistOffer({
    required String slotId,
    required AppointmentKind kind,
    String? familyMemberId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.claimSlot(slotId),
        data: {'type': _typeOf(kind), 'family_member_id': familyMemberId},
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Appointment> _patchAppointment(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.appointment(id),
        data: data,
      );
      return _appointment(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Отзывы о враче.
  ///
  /// Имени автора сервер не отдаёт — только `author_id`. Подставлять его в
  /// карточку нельзя (это чужой идентификатор), поэтому автор подписан так
  /// же, как в макете: «Пользователь N» по порядку в списке.
  @override
  Future<List<DoctorReview>> reviews(String doctorId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.doctorReviews(doctorId),
      );
      final items = response.data ?? const [];
      return [
        for (final (index, item) in items.indexed)
          () {
            final json = item as Map<String, dynamic>;
            return DoctorReview(
              id: json['id'] as String,
              authorName: 'Пользователь ${index + 1}',
              rating: (json['rating'] as num?)?.toDouble() ?? 0,
              text: (json['body'] as String? ?? '').trim(),
              createdAt: DateTime.tryParse(
                json['created_at'] as String? ?? '',
              )?.toLocal(),
            );
          }(),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<DoctorSpecialty>> specialties() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.doctorSpecialties,
      );
      return [
        for (final item in response.data ?? const [])
          DoctorSpecialty(
            id: item['specialty'] as String,
            title: item['specialty'] as String,
            doctorCount: (item['doctors_count'] as num).toInt(),
          ),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// ЭНДПОИНТА НЕТ. «Мои Врачи» — те, у кого пользователь уже был; вывести
  /// их можно только из прошлых записей, а в них нет ни врача, ни времени.
  @override
  Future<List<MyDoctor>> myDoctors() async => const [];

  static Doctor _doctor(Map<String, dynamic> json) {
    final discount = (json['discount_percent'] as num?)?.toInt() ?? 0;
    final full = (json['consult_price'] as num?)?.round();
    final forUser = (json['price_for_user'] as num?)?.round();

    final clinic = json['clinic'] as Map<String, dynamic>?;

    return Doctor(
      id: json['id'] as String,
      fullName: (json['full_name'] as String? ?? '').trim(),
      specialty: (json['specialty'] as String? ?? '').trim(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      experienceYears: (json['experience_years'] as num?)?.toInt(),
      clinic: (clinic?['name'] as String?)?.trim(),
      price: forUser ?? full,
      // Зачёркнутая цена нужна, только когда скидка есть: без неё в макете
      // рисуется одна цена.
      priceBeforeDiscount: discount > 0 ? full : null,
    );
  }

  static Appointment _appointment(Map<String, dynamic> json) {
    final doctor = json['doctor'] as Map<String, dynamic>? ?? const {};
    final price = (json['price'] as num?)?.round();
    return Appointment(
      id: json['id'] as String,
      specialty: (doctor['specialty'] as String? ?? '').trim(),
      kind: _kindFrom(json['type'] as String?),
      startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? '')?.toLocal(),
      doctorId: doctor['id'] as String?,
      doctorName: (doctor['full_name'] as String?)?.trim(),
      familyMemberId: json['family_member_id'] as String?,
      status: _statusFrom(json['status'] as String?),
      basePrice: price,
    );
  }

  static WaitlistEntry _waitlistEntry(Map<String, dynamic> json) =>
      WaitlistEntry(
        id: json['id'] as String,
        doctorId: json['doctor_id'] as String,
        status: switch (json['status']) {
          'active' => WaitlistEntryStatus.active,
          'fulfilled' => WaitlistEntryStatus.fulfilled,
          'cancelled' => WaitlistEntryStatus.cancelled,
          _ => WaitlistEntryStatus.unknown,
        },
        offeredSlotId: json['offered_slot_id'] as String?,
      );

  static AppointmentKind _kindFrom(String? value) => switch (value) {
    'video' => AppointmentKind.videoCall,
    'audio' => AppointmentKind.audioCall,
    'in_person' => AppointmentKind.inPerson,
    _ => AppointmentKind.chat,
  };

  static AppointmentStatus _statusFrom(String? value) => switch (value) {
    'pending' => AppointmentStatus.pending,
    'confirmed' => AppointmentStatus.confirmed,
    'completed' => AppointmentStatus.completed,
    'cancelled' => AppointmentStatus.cancelled,
    _ => AppointmentStatus.unknown,
  };
}
