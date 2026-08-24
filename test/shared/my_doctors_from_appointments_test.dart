import 'package:flutter_test/flutter_test.dart';
import 'package:medix/shared/data/my_doctors_from_appointments.dart';

void main() {
  test('оставляет завершённые записи нужного профиля и дедуплицирует', () {
    final raw = [
      _appointment('old', 'd1', '2026-07-01T10:00:00Z'),
      _appointment('pending', 'd3', '2026-08-22T10:00:00Z', status: 'pending'),
      _appointment('new', 'd1', '2026-08-20T10:00:00Z'),
      _appointment('second', 'd2', '2026-08-10T10:00:00Z'),
      _appointment(
        'family',
        'd4',
        '2026-08-23T10:00:00Z',
        familyMemberId: 'f1',
      ),
    ];

    final own = myDoctorsFromAppointments(raw);
    expect(own.map((doctor) => doctor.id), ['d1', 'd2']);
    expect(own.first.fullName, 'Врач d1');
    expect(own.first.photoUrl, 'https://cdn.example/d1.jpg');

    final family = myDoctorsFromAppointments(raw, familyMemberId: 'f1');
    expect(family.single.id, 'd4');
  });
}

Map<String, dynamic> _appointment(
  String id,
  String doctorId,
  String startsAt, {
  String status = 'completed',
  String? familyMemberId,
}) => {
  'id': id,
  'status': status,
  'starts_at': startsAt,
  'family_member_id': familyMemberId,
  'doctor': {
    'id': doctorId,
    'full_name': 'Врач $doctorId',
    'specialty': 'Терапевт',
    'photo_url': 'https://cdn.example/$doctorId.jpg',
  },
};
