import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/remote_doctors_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/canned_dio.dart';

/// Разбор ответов бэкенда `smart-med`: цена со скидкой, слоты и запись.
///
/// Тела ответов сняты со схем сервера (`app/schemas/doctor.py`,
/// `app/schemas/scheduling.py`), а не выдуманы.
void main() {
  group('врач', () {
    test('без подписки цена одна, зачёркивать нечего', () async {
      final (:dio, :adapter) = cannedDio({
        '/doctors/d1': (
          statusCode: 200,
          body: {
            'id': 'd1',
            'full_name': 'Имя Фамилия',
            'specialty': 'Гастроэнтеролог',
            'consult_price': 15000.0,
            'price_for_user': 15000.0,
            'discount_percent': 0,
            'discount_reason': null,
            'rating': 4.5,
            'clinic_id': null,
          },
        ),
      });

      final doctor = await RemoteDoctorsRepository(dio).doctor('d1');

      expect(doctor.price, 15000);
      expect(doctor.priceBeforeDiscount, isNull);
      expect(doctor.rating, 4.5);
      expect(adapter.requests.single.path, '/doctors/d1');
    });

    test('со скидкой показываем обе цены', () async {
      final (:dio, adapter: _) = cannedDio({
        '/doctors/d1': (
          statusCode: 200,
          body: {
            'id': 'd1',
            'full_name': 'Имя Фамилия',
            'specialty': 'Гастроэнтеролог',
            'consult_price': 15000.0,
            'price_for_user': 13500.0,
            'discount_percent': 10,
            'discount_reason': 'silver',
            'rating': 4.5,
            'clinic_id': null,
          },
        ),
      });

      final doctor = await RemoteDoctorsRepository(dio).doctor('d1');

      expect(doctor.price, 13500);
      expect(doctor.priceBeforeDiscount, 15000);
    });

    test('полей, которых у сервера нет, у врача не появляется', () async {
      final (:dio, adapter: _) = cannedDio({
        '/doctors/d1': (
          statusCode: 200,
          body: {
            'id': 'd1',
            'full_name': 'Имя Фамилия',
            'specialty': 'Гастроэнтеролог',
            'consult_price': null,
            'price_for_user': null,
            'discount_percent': 0,
            'discount_reason': null,
            'rating': 4.5,
            'clinic_id': '11111111-1111-1111-1111-111111111111',
          },
        ),
      });

      final doctor = await RemoteDoctorsRepository(dio).doctor('d1');

      // Клиника приходит идентификатором, развернуть его нечем; стажа,
      // города и фотографии у сервера нет вовсе.
      expect(doctor.clinic, isNull);
      expect(doctor.experienceYears, isNull);
      expect(doctor.experienceLabel, isNull);
      expect(doctor.city, isNull);
      expect(doctor.price, isNull);
    });
  });

  group('расписание', () {
    /// Слоты одного дня: занятый, свободный и свободный в другом дне.
    Map<String, CannedResponse> slots() => {
      '/doctors/d1/slots': (
        statusCode: 200,
        body: [
          {
            'id': 's-booked',
            'doctor_id': 'd1',
            'starts_at': '2026-08-13T09:30:00',
            'ends_at': '2026-08-13T10:00:00',
            'status': 'booked',
          },
          {
            'id': 's-second',
            'doctor_id': 'd1',
            'starts_at': '2026-08-13T15:30:00',
            'ends_at': '2026-08-13T16:00:00',
            'status': 'open',
          },
          {
            'id': 's-first',
            'doctor_id': 'd1',
            'starts_at': '2026-08-13T12:30:00',
            'ends_at': '2026-08-13T13:00:00',
            'status': 'open',
          },
          {
            'id': 's-next-day',
            'doctor_id': 'd1',
            'starts_at': '2026-08-14T09:30:00',
            'ends_at': '2026-08-14T10:00:00',
            'status': 'open',
          },
        ],
      ),
    };

    test('лента всегда в семь дней, слоты разложены по своим', () async {
      final (:dio, adapter: _) = cannedDio(slots());

      final schedule = await RemoteDoctorsRepository(
        dio,
      ).schedule('d1', from: DateTime(2026, 8, 13, 8));

      expect(schedule.days, hasLength(7));
      expect(schedule.days.first.date, DateTime(2026, 8, 13));
      expect(schedule.days[1].slots.single.id, 's-next-day');
      // Дни без слотов остаются в ленте пустыми — они рисуются серыми.
      expect(schedule.days.last.isAvailable, isFalse);
    });

    test(
      'занятые слоты в ленту не попадают, свободные идут по времени',
      () async {
        final (:dio, adapter: _) = cannedDio(slots());

        final schedule = await RemoteDoctorsRepository(
          dio,
        ).schedule('d1', from: DateTime(2026, 8, 13, 8));

        expect(schedule.days.first.slots.map((s) => s.id), [
          's-first',
          's-second',
        ]);
      },
    );

    test('прошедшее время первого дня отбрасывается', () async {
      final (:dio, adapter: _) = cannedDio(slots());

      // Час дня: 12:30 уже позади, 15:30 ещё впереди.
      final schedule = await RemoteDoctorsRepository(
        dio,
      ).schedule('d1', from: DateTime(2026, 8, 13, 13));

      expect(schedule.days.first.slots.single.id, 's-second');
    });

    test('границы недели уходят на сервер в ISO', () async {
      final (:dio, :adapter) = cannedDio(slots());

      await RemoteDoctorsRepository(
        dio,
      ).schedule('d1', from: DateTime(2026, 8, 13, 8));

      final query = adapter.requests.single.queryParameters;
      expect(query['from'], startsWith('2026-08-13T00:00:00'));
      // Конец седьмого дня, а не его начало: иначе он пришёл бы пустым.
      expect(query['to'], startsWith('2026-08-19T23:59:59'));
    });
  });

  group('запись', () {
    const doctor = Doctor(
      id: 'd1',
      fullName: 'Имя Фамилия',
      specialty: 'Гастроэнтеролог',
      rating: 4.5,
      price: 13500,
      priceBeforeDiscount: 15000,
    );
    final slot = ScheduleSlot(
      id: 's-first',
      startsAt: DateTime(2026, 8, 13, 12, 30),
    );

    test('уходит слотом и форматом, возвращается с временем выбора', () async {
      final (:dio, :adapter) = cannedDio({
        '/appointments': (
          statusCode: 201,
          body: {
            'id': 'ap-1',
            'slot_id': 's-first',
            'family_member_id': null,
            'type': 'video',
            'status': 'pending',
          },
        ),
      });
      final repository = RemoteDoctorsRepository(dio);

      final appointment = await repository.book(
        doctor: doctor,
        slot: slot,
        kind: AppointmentKind.videoCall,
      );

      // Тело до сериализации: адаптер видит запрос ровно таким, каким
      // его собрал репозиторий.
      final sent = adapter.requests.single.data! as Map;
      expect(sent['slot_id'], 's-first');
      expect(sent['type'], 'video');

      // Сервер отдаёт только идентификаторы и статус — время, специальность
      // и цены собираются из того, что и так было на экране.
      expect(appointment.id, 'ap-1');
      expect(appointment.startsAt, DateTime(2026, 8, 13, 12, 30));
      expect(appointment.specialty, 'Гастроэнтеролог');
      expect(appointment.basePrice, 15000);
      expect(appointment.goldPrice, 13500);
    });

    test('созданную запись потом можно открыть по идентификатору', () async {
      final (:dio, adapter: _) = cannedDio({
        '/appointments': (
          statusCode: 201,
          body: {
            'id': 'ap-1',
            'slot_id': 's-first',
            'family_member_id': null,
            'type': 'audio',
            'status': 'pending',
          },
        ),
      });
      final repository = RemoteDoctorsRepository(dio);

      await repository.book(
        doctor: doctor,
        slot: slot,
        kind: AppointmentKind.audioCall,
      );

      final opened = await repository.appointment('ap-1');
      expect(opened.kind, AppointmentKind.audioCall);
    });

    test('чужую запись открыть нечем — эндпоинта нет', () async {
      final (:dio, adapter: _) = cannedDio({});

      expect(
        () => RemoteDoctorsRepository(dio).appointment('ap-2'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
