import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/doctor_cabinet/data/repositories/doctor_schedule_repository.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_work_slot.dart';

import '../../helpers/canned_dio.dart';

/// Контракт взят из `smart-med/app/schemas/scheduling.py`.
void main() {
  const doctorId = '00000000-0000-0000-0000-000000000010';
  const slotId = '00000000-0000-0000-0000-000000000020';

  Map<String, Object> slot({String status = 'open'}) => {
    'id': slotId,
    'doctor_id': doctorId,
    'starts_at': '2026-08-24T06:00:00Z',
    'ends_at': '2026-08-24T06:30:00Z',
    'status': status,
  };

  test('читает собственное расписание с границами периода', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me/schedule': (statusCode: 200, body: [slot()]),
    });
    final from = DateTime.utc(2026, 8, 24);
    final to = DateTime.utc(2026, 8, 31);

    final result = await RemoteDoctorScheduleRepository(
      dio,
    ).schedule(from: from, to: to);

    expect(result.single.id, slotId);
    expect(result.single.doctorId, doctorId);
    expect(
      result.single.startsAt,
      DateTime.parse('2026-08-24T06:00:00Z').toLocal(),
    );
    expect(result.single.status, DoctorWorkSlotStatus.open);
    expect(adapter.requests.single.queryParameters, {
      'from': '2026-08-24T00:00:00.000Z',
      'to': '2026-08-31T00:00:00.000Z',
    });
  });

  test('создаёт список слотов в UTC и разбирает ответ', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /doctors/me/slots': (statusCode: 201, body: [slot()]),
    });

    final result = await RemoteDoctorScheduleRepository(dio).createSlots([
      DoctorWorkSlotDraft(
        startsAt: DateTime.utc(2026, 8, 24, 6),
        endsAt: DateTime.utc(2026, 8, 24, 6, 30),
      ),
    ]);

    expect(result.single.status, DoctorWorkSlotStatus.open);
    expect(adapter.requests.single.data, [
      {
        'starts_at': '2026-08-24T06:00:00.000Z',
        'ends_at': '2026-08-24T06:30:00.000Z',
      },
    ]);
  });

  test('удаляет только выбранный слот', () async {
    final (:dio, :adapter) = cannedDio({
      'DELETE /doctors/me/slots/$slotId': (statusCode: 204, body: {}),
    });

    await RemoteDoctorScheduleRepository(dio).deleteSlot(slotId);

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/doctors/me/slots/$slotId');
  });

  test('неизвестный статус не ломает расписание', () async {
    final (:dio, adapter: _) = cannedDio({
      '/doctors/me/schedule': (
        statusCode: 200,
        body: [slot(status: 'future_status')],
      ),
    });

    final result = await RemoteDoctorScheduleRepository(
      dio,
    ).schedule(from: DateTime.utc(2026, 8, 24), to: DateTime.utc(2026, 8, 31));

    expect(result.single.status, DoctorWorkSlotStatus.unknown);
  });
}
