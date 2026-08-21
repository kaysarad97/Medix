import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/profile/data/repositories/'
    'remote_profile_repository.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';
import 'package:medix/shared/models/gender.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/canned_dio.dart';

/// Разбор профиля и мед-карты бэкенда `smart-med`.
///
/// Мед-карта на сервере — лента записей с типом и `payload`
/// (`app/schemas/medical.py`), а не документ: здесь проверяется, что она
/// правильно складывается при чтении и раскладывается при сохранении.
void main() {
  CannedResponse me() => (
    statusCode: 200,
    body: {
      'id': 'u1',
      'email': 'user@medix.kz',
      'full_name': 'Фамилия Имя',
      'birth_date': '1996-12-06',
      'sex': 'male',
      'iin': '961206300123',
      'role': 'patient',
      'phone': null,
      'phone_verified_at': null,
      'email_verified_at': '2026-08-09T10:00:00',
      'avatar_s3_key': null,
      'avatar_url': 'https://storage.example/avatar.jpg',
    },
  );

  group('профиль', () {
    test('ФИО режется, тариф берётся из подписки', () async {
      final (:dio, adapter: _) = cannedDio({
        '/users/me': me(),
        '/subscriptions/me': (
          statusCode: 200,
          body: {
            'id': 's1',
            'plan_code': 'silver',
            'status': 'active',
            'period_end': '2026-09-09T10:00:00',
            'cancel_at_period_end': false,
          },
        ),
      });

      final profile = await RemoteProfileRepository(dio).profile();

      // Порядок обратный семье: на регистрации поле подписано «ФИО».
      expect(profile.lastName, 'Фамилия');
      expect(profile.firstName, 'Имя');
      expect(profile.email, 'user@medix.kz');
      expect(profile.subscription, SubscriptionTier.silver);
    });

    test('без подписки тариф бесплатный, а не ошибка', () async {
      // 404 на `/subscriptions/me` — нормальный ответ сервера.
      final (:dio, adapter: _) = cannedDio({'/users/me': me()});

      final profile = await RemoteProfileRepository(dio).profile();

      expect(profile.subscription, SubscriptionTier.free);
    });

    test('незнакомый тариф считается отсутствием подписки', () async {
      // Gold сняли с продажи, и разбирать его код клиент больше не умеет.
      // Старый сервер с такой подпиской не должен открывать платные
      // разделы «на всякий случай» — это решает подписка, а не клиент.
      final (:dio, adapter: _) = cannedDio({
        '/users/me': me(),
        '/subscriptions/me': (
          statusCode: 200,
          body: {
            'id': 's1',
            'plan_code': 'gold',
            'status': 'active',
            'period_end': '2026-09-09T10:00:00',
            'cancel_at_period_end': false,
          },
        ),
      });

      final profile = await RemoteProfileRepository(dio).profile();

      expect(profile.subscription, SubscriptionTier.free);
    });

    test('пол, дата рождения и ИИН приходят с сервера', () async {
      // До 17 августа 2026 их не было в ответе, и в шапке стоял прочерк.
      final (:dio, adapter: _) = cannedDio({'/users/me': me()});

      final profile = await RemoteProfileRepository(dio).profile();

      expect(profile.gender, Gender.male);
      expect(profile.genderLabel, 'мужчина');
      expect(profile.birthDate, DateTime(1996, 12, 6));
      expect(profile.iin, '961206300123');
      expect(profile.ageLabel(DateTime(2026, 8, 13)), '29 лет');
      expect(profile.avatarUrl, endsWith('avatar.jpg'));
    });

    test('разрешённые поля профиля отправляются одним PATCH', () async {
      final (:dio, :adapter) = cannedDio({'PATCH /users/me': me()});
      final source = UserProfile(
        id: 'u1',
        firstName: 'Имя',
        lastName: 'Фамилия',
        subscription: SubscriptionTier.silver,
        gender: Gender.female,
        birthDate: DateTime(1996, 12, 6),
        iin: '961206300123',
      );

      final saved = await RemoteProfileRepository(dio).saveProfile(source);

      expect(saved.avatarUrl, endsWith('avatar.jpg'));
      expect(adapter.requests.single.data, {
        'full_name': 'Фамилия Имя',
        'birth_date': '1996-12-06',
        'sex': 'female',
        'iin': '961206300123',
      });
    });

    test('аватар загружается через билет и подтверждение S3-ключа', () async {
      final (:dio, :adapter) = cannedDio({
        'POST /users/me/avatar/upload-url': (
          statusCode: 200,
          body: {
            'upload_url': 'https://storage.example/upload',
            'fields': {'policy': 'signed'},
            'key': 'avatars/u1/avatar.png',
            'expires_at': '2026-08-21T12:00:00Z',
          },
        ),
        'POST /users/me/avatar': me(),
        '/subscriptions/me': (
          statusCode: 404,
          body: {'detail': 'Подписка не найдена'},
        ),
      });
      final repository = RemoteProfileRepository(dio);

      final ticket = await repository.requestAvatarUpload(
        filename: 'avatar.png',
        contentType: 'image/png',
      );
      final profile = await repository.confirmAvatar(ticket.key);

      expect(ticket.fields['policy'], 'signed');
      expect(profile.avatarUrl, endsWith('avatar.jpg'));
      expect(adapter.requests[1].data, {'avatar_s3_key': ticket.key});
    });
  });

  group('мед-карта складывается из записей', () {
    CannedResponse records() => (
      statusCode: 200,
      body: [
        {
          'id': 'r1',
          'family_member_id': null,
          'record_type': 'blood_type',
          'payload': {'group': 'AB', 'rh': 'negative'},
          'created_by': 'u1',
          'superseded_by': null,
          'created_at': '2026-08-09T10:00:00',
        },
        {
          'id': 'r2',
          'family_member_id': null,
          'record_type': 'allergy',
          'payload': {'title': 'Аллергии', 'details': 'Пенициллин'},
          'created_by': 'u1',
          'superseded_by': null,
          'created_at': '2026-08-09T10:00:00',
        },
        {
          'id': 'r3',
          'family_member_id': null,
          'record_type': 'measurement',
          'payload': {
            'kind': 'height',
            'value': 176,
            'unit': 'cm',
            'measured_at': '2026-08-09T10:00:00',
          },
          'created_by': 'u1',
          'superseded_by': null,
          'created_at': '2026-08-09T10:00:00',
        },
        {
          'id': 'r4',
          'family_member_id': null,
          'record_type': 'note',
          'payload': {'title': 'Вредные привычки', 'details': 'да'},
          'created_by': 'u1',
          'superseded_by': null,
          'created_at': '2026-08-09T10:00:00',
        },
      ],
    );

    test('группа крови и резус приходят своим типом', () async {
      final (:dio, adapter: _) = cannedDio({
        '/users/me/medical-records': records(),
      });

      final card = await RemoteProfileRepository(dio).medicalCard();

      expect(card.bloodGroup, BloodGroup.fourth);
      expect(card.rhesus, RhesusFactor.negative);
    });

    test('рост приходит замером, остальное — по типу и заголовку', () async {
      final (:dio, adapter: _) = cannedDio({
        '/users/me/medical-records': records(),
      });

      final card = await RemoteProfileRepository(dio).medicalCard();

      expect(card.allergies, 'Пенициллин');
      expect(card.heightCm, 176);
      expect(card.hasBadHabits, isTrue);
      // Веса среди записей нет — поле остаётся пустым, а не нулевым.
      expect(card.weightKg, isNull);
    });
  });

  group('история замеров', () {
    CannedResponse history() => (
      statusCode: 200,
      body: [
        {
          'id': 'm1',
          'family_member_id': null,
          'record_type': 'measurement',
          'payload': {
            'kind': 'weight',
            'value': 76.5,
            'unit': 'kg',
            'measured_at': '2026-08-20T10:00:00Z',
          },
          'created_by': 'u1',
          'superseded_by': 'm2',
          'created_at': '2026-08-20T10:00:00Z',
        },
      ],
    );

    test('личная история передаёт вид замера и период', () async {
      final (:dio, :adapter) = cannedDio({
        '/users/me/medical-records/history': history(),
      });

      final result = await RemoteProfileRepository(dio).measurementHistory(
        MeasurementKind.weight,
        from: DateTime.utc(2026, 8, 1),
        to: DateTime.utc(2026, 8, 31),
      );

      expect(result.single.value, 76.5);
      expect(result.single.unit, 'kg');
      expect(result.single.kind, MeasurementKind.weight);
      expect(adapter.requests.single.queryParameters, {
        'kind': 'weight',
        'from': '2026-08-01T00:00:00.000Z',
        'to': '2026-08-31T00:00:00.000Z',
      });
    });

    test('история члена семьи использует защищённый семейный путь', () async {
      final (:dio, :adapter) = cannedDio({
        '/users/me/family/f1/medical-records/history': history(),
      });

      await RemoteProfileRepository(
        dio,
      ).measurementHistory(MeasurementKind.height, familyMemberId: 'f1');

      expect(
        adapter.requests.single.path,
        '/users/me/family/f1/medical-records/history',
      );
      expect(adapter.requests.single.queryParameters, {'kind': 'height'});
    });
  });

  test(
    'предыдущие процедуры собираются из завершённых личных записей',
    () async {
      Map<String, dynamic> appointment({
        required String id,
        required String status,
        String? familyMemberId,
      }) => {
        'id': id,
        'slot_id': 'slot-$id',
        'family_member_id': familyMemberId,
        'type': 'in_person',
        'status': status,
        'starts_at': '2026-08-10T10:30:00Z',
        'ends_at': '2026-08-10T11:00:00Z',
        'price': 15000.0,
        'doctor': {
          'id': 'd1',
          'full_name': 'Айжан Садыкова',
          'specialty': 'Терапевт',
          'photo_url': null,
          'clinic': null,
        },
      };
      final (:dio, :adapter) = cannedDio({
        'GET /appointments': (
          statusCode: 200,
          body: [
            appointment(id: 'done', status: 'completed'),
            appointment(id: 'future', status: 'confirmed'),
            appointment(
              id: 'family',
              status: 'completed',
              familyMemberId: 'f1',
            ),
          ],
        ),
      });

      final result = await RemoteProfileRepository(dio).procedures();

      expect(result, hasLength(1));
      expect(result.single.id, 'done');
      expect(result.single.doctorName, 'Айжан Садыкова');
      expect(result.single.specialty, 'Терапевт');
      expect(adapter.requests.single.queryParameters, {
        'upcoming': false,
        'limit': 100,
      });
    },
  );

  group('мед-карта раскладывается обратно', () {
    test('новое заводится POST, известное правится PATCH', () async {
      final (:dio, :adapter) = cannedDio({
        '/users/me/medical-records': (
          statusCode: 200,
          body: [
            {
              'id': 'r1',
              'family_member_id': null,
              'record_type': 'blood_type',
              'payload': {'group': 'O', 'rh': 'positive'},
              'created_by': 'u1',
              'superseded_by': null,
              'created_at': '2026-08-09T10:00:00',
            },
          ],
        ),
        '/users/me/medical-records/r1': (statusCode: 200, body: {}),
        // По тому же пути, что и список, но ответ другой — одна запись.
        'POST /users/me/medical-records': (statusCode: 201, body: {}),
      });

      await RemoteProfileRepository(dio).saveMedicalCard(
        const MedicalCard(
          bloodGroup: BloodGroup.second,
          rhesus: RhesusFactor.positive,
          heightCm: 176,
        ),
      );

      final writes = adapter.requests
          .where((r) => r.method != 'GET')
          .map((r) => (r.method, r.path, r.data! as Map))
          .toList();

      // Группа крови уже была — правим её же запись; роста не было — заводим.
      expect(writes, hasLength(2));
      expect(writes.first.$1, 'PATCH');
      expect(writes.first.$2, '/users/me/medical-records/r1');
      expect(writes.first.$3['payload'], {'group': 'A', 'rh': 'positive'});

      expect(writes.last.$1, 'POST');
      expect(writes.last.$2, '/users/me/medical-records');
      expect(writes.last.$3['record_type'], 'measurement');
      final payload = writes.last.$3['payload'] as Map;
      expect(payload['kind'], 'height');
      expect(payload['value'], 176);
      expect(payload['unit'], 'cm');
      // Время замера ставится само: в макете мед-карты его не спрашивают.
      expect(payload['measured_at'], isNotEmpty);
    });

    test('пустые поля не отправляются вовсе', () async {
      final (:dio, :adapter) = cannedDio({
        '/users/me/medical-records': (statusCode: 200, body: []),
      });

      // Удаления у записей нет, и пустая заметка осталась бы в ленте
      // навсегда — поэтому пустое не отправляем.
      await RemoteProfileRepository(
        dio,
      ).saveMedicalCard(const MedicalCard(allergies: '   ', surgeries: null));

      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    });
  });
}
