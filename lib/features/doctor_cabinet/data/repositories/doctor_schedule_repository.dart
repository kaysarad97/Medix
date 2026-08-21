import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/doctor_work_slot.dart';

abstract interface class DoctorScheduleRepository {
  Future<List<DoctorWorkSlot>> schedule({
    required DateTime from,
    required DateTime to,
  });

  Future<List<DoctorWorkSlot>> createSlots(List<DoctorWorkSlotDraft> slots);

  Future<void> deleteSlot(String id);
}

class RemoteDoctorScheduleRepository implements DoctorScheduleRepository {
  const RemoteDoctorScheduleRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<DoctorWorkSlot>> schedule({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.myDoctorSchedule,
        queryParameters: {
          'from': from.toUtc().toIso8601String(),
          'to': to.toUtc().toIso8601String(),
        },
      );
      return _slots(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<DoctorWorkSlot>> createSlots(
    List<DoctorWorkSlotDraft> slots,
  ) async {
    try {
      final response = await _dio.post<List<dynamic>>(
        ApiEndpoints.myDoctorSlots,
        data: [
          for (final slot in slots)
            {
              'starts_at': slot.startsAt.toUtc().toIso8601String(),
              'ends_at': slot.endsAt.toUtc().toIso8601String(),
            },
        ],
      );
      return _slots(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<void> deleteSlot(String id) async {
    try {
      await _dio.delete<void>(ApiEndpoints.myDoctorSlot(id));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static List<DoctorWorkSlot> _slots(List<dynamic>? raw) => [
    for (final item in raw ?? const [])
      _slot(Map<String, dynamic>.from(item as Map)),
  ];

  static DoctorWorkSlot _slot(Map<String, dynamic> json) => DoctorWorkSlot(
    id: json['id'] as String,
    doctorId: json['doctor_id'] as String,
    startsAt: DateTime.parse(json['starts_at'] as String).toLocal(),
    endsAt: DateTime.parse(json['ends_at'] as String).toLocal(),
    status: switch (json['status']) {
      'open' => DoctorWorkSlotStatus.open,
      'held' => DoctorWorkSlotStatus.held,
      'booked' => DoctorWorkSlotStatus.booked,
      'cancelled' => DoctorWorkSlotStatus.cancelled,
      _ => DoctorWorkSlotStatus.unknown,
    },
  );
}

/// Локальный вариант нужен для запуска всего приложения с
/// `MEDIX_USE_MOCKS=true`; экран управления слотами будет подключён отдельно.
class MockDoctorScheduleRepository implements DoctorScheduleRepository {
  const MockDoctorScheduleRepository();

  @override
  Future<List<DoctorWorkSlot>> schedule({
    required DateTime from,
    required DateTime to,
  }) async => const [];

  @override
  Future<List<DoctorWorkSlot>> createSlots(
    List<DoctorWorkSlotDraft> slots,
  ) async => const [];

  @override
  Future<void> deleteSlot(String id) async {}
}
