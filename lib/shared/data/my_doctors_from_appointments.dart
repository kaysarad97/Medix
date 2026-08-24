import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../models/my_doctor.dart';

const _appointmentsPageSize = 100;

/// Загружает всю историю записей постранично: сервер сортирует её от старых
/// записей к новым, поэтому одного первого page недостаточно для свежих врачей.
Future<List<MyDoctor>> fetchMyDoctorsFromAppointments(
  Dio dio, {
  String? familyMemberId,
}) async {
  final appointments = <dynamic>[];
  var offset = 0;
  while (true) {
    final response = await dio.get<List<dynamic>>(
      ApiEndpoints.appointments,
      queryParameters: {
        'upcoming': false,
        'limit': _appointmentsPageSize,
        if (offset > 0) 'offset': offset,
      },
    );
    final page = response.data ?? const <dynamic>[];
    appointments.addAll(page);
    if (page.length < _appointmentsPageSize) break;
    offset += page.length;
  }
  return myDoctorsFromAppointments(
    appointments,
    familyMemberId: familyMemberId,
  );
}

/// Собирает «Моих врачей» из завершённых записей.
///
/// Отдельного endpoint нет, но `GET /appointments` уже содержит вложенный
/// `DoctorSummary` и `family_member_id`. Сначала сортируем записи от новых к
/// старым, затем оставляем последнюю встречу с каждым врачом.
List<MyDoctor> myDoctorsFromAppointments(
  Iterable<dynamic> raw, {
  String? familyMemberId,
}) {
  final appointments =
      <Map<String, dynamic>>[
        for (final item in raw)
          if (item is Map<String, dynamic> &&
              item['status'] == 'completed' &&
              item['family_member_id'] == familyMemberId)
            item,
      ]..sort((a, b) {
        final aDate = DateTime.tryParse(a['starts_at'] as String? ?? '');
        final bDate = DateTime.tryParse(b['starts_at'] as String? ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

  final byId = <String, MyDoctor>{};
  for (final appointment in appointments) {
    final doctor = appointment['doctor'];
    if (doctor is! Map<String, dynamic>) continue;
    final id = (doctor['id'] as String? ?? '').trim();
    final fullName = (doctor['full_name'] as String? ?? '').trim();
    if (id.isEmpty || fullName.isEmpty || byId.containsKey(id)) continue;
    byId[id] = MyDoctor(
      id: id,
      fullName: fullName,
      specialty: (doctor['specialty'] as String? ?? '').trim(),
      photoUrl: doctor['photo_url'] as String?,
    );
  }
  return byId.values.toList(growable: false);
}
