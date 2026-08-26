import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/family_access/data/repositories/family_repository.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('врачи члена семьи фильтруются по family_member_id', () async {
    final (:dio, :adapter) = cannedDio({
      '/appointments': (
        statusCode: 200,
        body: [
          _appointment('own', null, 'd1'),
          _appointment('family', 'f1', 'd2'),
          _appointment('other-family', 'f2', 'd3'),
        ],
      ),
    });

    final doctors = await RemoteFamilyRepository(dio).doctorsOf('f1');

    expect(doctors.single.id, 'd2');
    expect(adapter.requests.single.queryParameters['upcoming'], isFalse);
    expect(adapter.requests.single.queryParameters['limit'], 100);
  });
}

Map<String, dynamic> _appointment(
  String id,
  String? familyMemberId,
  String doctorId,
) => {
  'id': id,
  'status': 'completed',
  'starts_at': '2026-08-20T10:00:00Z',
  'family_member_id': familyMemberId,
  'doctor': {
    'id': doctorId,
    'full_name': 'Врач $doctorId',
    'specialty': 'Терапевт',
    'photo_url': null,
  },
};
