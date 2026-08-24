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
    test('специальности приходят отдельным списком со счётчиками', () async {
      final (:dio, :adapter) = cannedDio({
        '/doctors/specialties': (
          statusCode: 200,
          body: [
            {'specialty': 'Кардиолог', 'doctors_count': 7},
          ],
        ),
      });

      final specialties = await RemoteDoctorsRepository(dio).specialties();

      expect(specialties.single.title, 'Кардиолог');
      expect(specialties.single.doctorCount, 7);
      expect(adapter.requests.single.path, '/doctors/specialties');
    });

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

    test('стаж, отзывы и клиника приходят с сервера', () async {
      // До 17 августа 2026 их не было в ответе, и в карточках стояли
      // захардкоженные «4.5», «100 отзывов», «Стаж 10 лет» и «Название
      // клиники».
      final (:dio, adapter: _) = cannedDio({
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
            'rating': 4.7,
            'reviews_count': 12,
            'experience_years': 8,
            'clinic': {
              'id': '11111111-1111-1111-1111-111111111111',
              'name': 'Клиника «Здоровье»',
            },
          },
        ),
      });

      final doctor = await RemoteDoctorsRepository(dio).doctor('d1');

      expect(doctor.rating, 4.7);
      expect(doctor.reviewsCount, 12);
      expect(doctor.experienceYears, 8);
      expect(doctor.clinic, 'Клиника «Здоровье»');
      // Города и фотографии у сервера по-прежнему нет.
      expect(doctor.city, isNull);
      expect(doctor.photoUrl, isNull);
    });

    test('без клиники и стажа поля остаются пустыми', () async {
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
            'reviews_count': 0,
            'experience_years': null,
            'clinic': null,
          },
        ),
      });

      final doctor = await RemoteDoctorsRepository(dio).doctor('d1');

      expect(doctor.clinic, isNull);
      expect(doctor.experienceYears, isNull);
      expect(doctor.experienceLabel, isNull);
      expect(doctor.price, isNull);
    });

    test('отзывы приходят своим эндпоинтом', () async {
      final (:dio, :adapter) = cannedDio({
        '/doctors/d1/reviews': (
          statusCode: 200,
          body: [
            {
              'id': 'r1',
              'doctor_id': 'd1',
              'author_id': 'u9',
              'consultation_id': 'c1',
              'rating': 5,
              'body': 'Внимательный врач',
              'created_at': '2026-08-10T09:00:00',
            },
          ],
        ),
      });

      final reviews = await RemoteDoctorsRepository(dio).reviews('d1');

      expect(reviews.single.rating, 5);
      expect(reviews.single.text, 'Внимательный врач');
      // Имени автора сервер не отдаёт — только идентификатор, подставлять
      // его в карточку нельзя.
      expect(reviews.single.authorName, 'Пользователь 1');
      expect(adapter.requests.single.path, '/doctors/d1/reviews');
    });

    test('мои врачи собираются из завершённых записей', () async {
      final (:dio, :adapter) = cannedDio({
        '/appointments': (
          statusCode: 200,
          body: [
            {
              'id': 'a1',
              'status': 'completed',
              'starts_at': '2026-08-20T10:00:00Z',
              'family_member_id': null,
              'doctor': {
                'id': 'd1',
                'full_name': 'Айжан Садыкова',
                'specialty': 'Кардиолог',
                'photo_url': 'https://cdn.example/d1.jpg',
              },
            },
          ],
        ),
      });

      final doctors = await RemoteDoctorsRepository(dio).myDoctors();

      expect(doctors.single.id, 'd1');
      expect(doctors.single.specialty, 'Кардиолог');
      expect(adapter.requests.single.queryParameters, {
        'upcoming': false,
        'limit': 100,
      });
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

    Map<String, dynamic> appointmentJson({
      String id = 'ap-1',
      String type = 'video',
      String status = 'pending',
      String startsAt = '2026-08-13T12:30:00',
      String? cancellationReason,
    }) => {
      'id': id,
      'slot_id': 's-first',
      'family_member_id': null,
      'consultation_id': 'c-ap-1',
      'type': type,
      'status': status,
      'starts_at': startsAt,
      'ends_at': '2026-08-13T13:00:00',
      'price': 13500.0,
      'cancellation_reason': cancellationReason,
      'doctor': {
        'id': 'd1',
        'full_name': 'Имя Фамилия',
        'specialty': 'Гастроэнтеролог',
        'photo_url': null,
        'clinic': null,
      },
    };

    test('уходит слотом и форматом, возвращается с временем выбора', () async {
      final (:dio, :adapter) = cannedDio({
        '/appointments': (statusCode: 201, body: appointmentJson()),
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

      // Сервер возвращает развёрнутую запись, поэтому она восстановится и
      // после перезапуска приложения.
      expect(appointment.id, 'ap-1');
      expect(appointment.startsAt, DateTime(2026, 8, 13, 12, 30));
      expect(appointment.specialty, 'Гастроэнтеролог');
      expect(appointment.basePrice, 13500);
      expect(appointment.doctorName, 'Имя Фамилия');
    });

    test('созданную запись потом можно открыть по идентификатору', () async {
      final (:dio, adapter: _) = cannedDio({
        'POST /appointments': (
          statusCode: 201,
          body: appointmentJson(type: 'audio'),
        ),
        'GET /appointments/ap-1': (
          statusCode: 200,
          body: appointmentJson(type: 'audio'),
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
      expect(opened.consultationId, 'c-ap-1');
    });

    test('неизвестная запись возвращает серверную ошибку', () async {
      final (:dio, adapter: _) = cannedDio({});

      expect(
        () => RemoteDoctorsRepository(dio).appointment('ap-2'),
        throwsA(isA<Exception>()),
      );
    });

    test('причина отмены врача читается из записи пациента', () async {
      final (:dio, adapter: _) = cannedDio({
        'GET /appointments/ap-1': (
          statusCode: 200,
          body: appointmentJson(
            status: 'cancelled',
            cancellationReason: 'Врач заболел',
          ),
        ),
      });

      final appointment = await RemoteDoctorsRepository(
        dio,
      ).appointment('ap-1');

      expect(appointment.status, AppointmentStatus.cancelled);
      expect(appointment.cancellationReason, 'Врач заболел');
    });

    test('список записей приходит развёрнутым', () async {
      final (:dio, :adapter) = cannedDio({
        'GET /appointments': (
          statusCode: 200,
          body: [appointmentJson(status: 'no_show')],
        ),
      });

      final result = await RemoteDoctorsRepository(
        dio,
      ).appointments(upcoming: true);

      expect(result.single.doctorId, 'd1');
      expect(result.single.status, AppointmentStatus.noShow);
      expect(adapter.requests.single.queryParameters['upcoming'], isTrue);
    });

    test('перенос и отмена отправляют action через PATCH', () async {
      final (:dio, :adapter) = cannedDio({
        'PATCH /appointments/ap-1': (
          statusCode: 200,
          body: appointmentJson(status: 'cancelled'),
        ),
      });
      final repository = RemoteDoctorsRepository(dio);

      await repository.reschedule('ap-1', slot);
      await repository.cancel('ap-1');

      expect(adapter.requests[0].data, {
        'action': 'reschedule',
        'new_slot_id': 's-first',
      });
      expect(adapter.requests[1].data, {'action': 'cancel'});
    });
  });

  group('лист ожидания', () {
    test('создание, список и отмена используют отдельный ресурс', () async {
      final entry = {
        'id': 'w1',
        'doctor_id': 'd1',
        'status': 'active',
        'offered_slot_id': 's1',
      };
      final (:dio, :adapter) = cannedDio({
        'POST /waitlist': (statusCode: 201, body: entry),
        'GET /waitlist': (statusCode: 200, body: [entry]),
        'DELETE /waitlist/w1': (statusCode: 204, body: const {}),
      });
      final repository = RemoteDoctorsRepository(dio);

      final created = await repository.joinWaitlist('d1');
      final listed = await repository.waitlistEntries();
      await repository.leaveWaitlist('w1');

      expect(created.offeredSlotId, 's1');
      expect(created.hasOffer, isTrue);
      expect(listed.single.status, WaitlistEntryStatus.active);
      expect(adapter.requests.first.data, {'doctor_id': 'd1'});
      expect(adapter.requests.last.path, '/waitlist/w1');
    });

    test('предложенный слот бронируется с форматом и членом семьи', () async {
      final (:dio, :adapter) = cannedDio({
        '/slots/s1/claim': (
          statusCode: 201,
          body: {
            'id': 'ap-1',
            'slot_id': 's1',
            'family_member_id': 'f1',
            'type': 'audio',
            'status': 'confirmed',
            'starts_at': '2026-08-22T10:00:00Z',
            'ends_at': '2026-08-22T10:30:00Z',
            'price': 10000,
            'doctor': {
              'id': 'd1',
              'full_name': 'Имя Фамилия',
              'specialty': 'Терапевт',
              'photo_url': null,
              'clinic': null,
            },
          },
        ),
      });

      final result = await RemoteDoctorsRepository(dio).claimWaitlistOffer(
        slotId: 's1',
        kind: AppointmentKind.audioCall,
        familyMemberId: 'f1',
      );

      expect(result.id, 'ap-1');
      expect(adapter.requests.single.data, {
        'type': 'audio',
        'family_member_id': 'f1',
      });
    });
  });
}
