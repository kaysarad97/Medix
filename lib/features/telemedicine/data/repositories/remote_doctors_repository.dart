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
/// Чего у сервера нет: клиники по имени (приходит только `clinic_id`),
/// стажа, числа отзывов, города и фотографии врача. Эти поля остаются
/// пустыми, и экраны их не рисуют.
class RemoteDoctorsRepository implements DoctorsRepository {
  RemoteDoctorsRepository(this._dio);

  final Dio _dio;

  /// Записи, созданные в этом запуске.
  ///
  /// ЭНДПОИНТА НЕТ. Сервер отдаёт список своих записей (`GET /appointments`),
  /// но в каждой только `slot_id` — ни времени, ни врача, — и получить слот
  /// по идентификатору нечем. Показать запись можно лишь ту, которую сами
  /// же и создали, пока помним её состав; после перезапуска экран «Ваша
  /// Запись» останется пустым. Вопрос бэкенду: `GET /appointments/{id}` с
  /// разложенным слотом и врачом.
  final Map<String, Appointment> _booked = {};

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

      final appointment = Appointment(
        id: response.data!['id'] as String,
        specialty: doctor.specialty,
        kind: kind,
        startsAt: slot.startsAt,
        doctorId: doctor.id,
        basePrice: doctor.priceBeforeDiscount ?? doctor.price,
        goldPrice: doctor.priceBeforeDiscount == null ? null : doctor.price,
      );
      _booked[appointment.id] = appointment;
      return appointment;
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
    final booked = _booked[id];
    if (booked != null) return booked;

    throw const ApiException(
      'Запись не найдена. Откройте её сразу после оформления.',
      statusCode: 404,
    );
  }

  /// ЭНДПОИНТА НЕТ. Отзывов у бэкенда нет вовсе — приходит только средний
  /// рейтинг числом. Свои отзывы живут в `composedReviewsProvider`.
  @override
  Future<List<DoctorReview>> reviews(String doctorId) async => const [];

  /// ЭНДПОИНТА НЕТ. Специальности сервер списком не отдаёт; собрать их из
  /// каталога можно, но количество врачей в каждой — уже нет, а на макете
  /// оно подписано под каждой плиткой.
  @override
  Future<List<DoctorSpecialty>> specialties() async => const [];

  /// ЭНДПОИНТА НЕТ. «Мои Врачи» — те, у кого пользователь уже был; вывести
  /// их можно только из прошлых записей, а в них нет ни врача, ни времени.
  @override
  Future<List<MyDoctor>> myDoctors() async => const [];

  static Doctor _doctor(Map<String, dynamic> json) {
    final discount = (json['discount_percent'] as num?)?.toInt() ?? 0;
    final full = (json['consult_price'] as num?)?.round();
    final forUser = (json['price_for_user'] as num?)?.round();

    return Doctor(
      id: json['id'] as String,
      fullName: (json['full_name'] as String? ?? '').trim(),
      specialty: (json['specialty'] as String? ?? '').trim(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      price: forUser ?? full,
      // Зачёркнутая цена нужна, только когда скидка есть: без неё в макете
      // рисуется одна цена.
      priceBeforeDiscount: discount > 0 ? full : null,
    );
  }
}
