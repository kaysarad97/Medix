import 'package:medix/features/doctor_cabinet/data/repositories/doctor_schedule_repository.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_work_slot.dart';

/// Заглушка с изменяемым списком слотов в памяти — тесты проверяют, что
/// добавление и удаление реально доходят до экрана, а не только до мока.
class FakeDoctorScheduleRepository implements DoctorScheduleRepository {
  FakeDoctorScheduleRepository({List<DoctorWorkSlot>? initial})
    : _slots = [...?initial];

  final List<DoctorWorkSlot> _slots;
  var _nextId = 1;

  @override
  Future<List<DoctorWorkSlot>> schedule({
    required DateTime from,
    required DateTime to,
  }) async => _slots
      .where(
        (slot) => !slot.startsAt.isBefore(from) && !slot.startsAt.isAfter(to),
      )
      .toList();

  @override
  Future<List<DoctorWorkSlot>> createSlots(
    List<DoctorWorkSlotDraft> slots,
  ) async {
    final created = [
      for (final draft in slots)
        DoctorWorkSlot(
          id: 'fake-slot-${_nextId++}',
          doctorId: 'd1',
          startsAt: draft.startsAt,
          endsAt: draft.endsAt,
          status: DoctorWorkSlotStatus.open,
        ),
    ];
    _slots.addAll(created);
    return created;
  }

  @override
  Future<void> deleteSlot(String id) async {
    _slots.removeWhere((slot) => slot.id == id);
  }
}
