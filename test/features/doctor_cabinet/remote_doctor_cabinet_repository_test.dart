import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/doctor_cabinet/data/repositories/remote_doctor_cabinet_repository.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_profile.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/canned_dio.dart';

/// Контракты взяты из `smart-med/app/schemas/doctor.py` и
/// `smart-med/app/schemas/scheduling.py` от 24 августа 2026 года.
void main() {
  const doctorId = '00000000-0000-0000-0000-000000000010';
  const appointmentId = '00000000-0000-0000-0000-000000000020';
  const patientId = '00000000-0000-0000-0000-000000000030';
  const consultationId = '00000000-0000-0000-0000-000000000040';

  Map<String, Object?> doctorMe({String fullName = 'Айжан Садыкова'}) => {
    'id': doctorId,
    'full_name': fullName,
    'phone': '+77010000000',
    'email': 'doctor@medix.kz',
    'specialty': 'Кардиолог',
    'license_number': '11233МК',
    'consult_price': 12000,
    'city': 'Алматы',
    'photo_url': 'https://cdn.example/doctor.jpg',
    'verification_status': 'approved',
    'rejection_reason': null,
    'credential_url': 'https://cdn.example/Документ%201.pdf?signature=test',
    'experience_since': '2016-01-01',
    'experience_years': 10,
    'rating': 4.8,
    'reviews_count': 12,
    'clinic': {'id': 'clinic-1', 'name': 'MedIx Clinic'},
    'created_at': '2026-08-01T10:00:00Z',
  };

  Map<String, Object?> appointment({
    String id = appointmentId,
    String patient = patientId,
    String fullName = 'Дархан Аркалыков',
    String startsAt = '2026-08-24T07:30:00Z',
    String type = 'video',
    bool detailed = false,
  }) => {
    'id': id,
    'type': type,
    'status': 'confirmed',
    'starts_at': startsAt,
    'ends_at': '2026-08-24T08:15:00Z',
    'patient': {
      'id': patient,
      'full_name': fullName,
      'birth_date': '2000-12-30',
      'sex': 'male',
      'is_family_member': false,
    },
    if (detailed) ...{
      'price': 12000,
      'cancellation_reason': null,
      'consultation_id': consultationId,
      'patient_phone': null,
      'files': <Object>[],
      'conclusion': {
        'id': 'conclusion-1',
        'family_member_id': null,
        'appointment_id': id,
        'record_type': 'conclusion',
        'payload': {'text': 'Состояние стабильное'},
        'created_by': doctorId,
        'superseded_by': null,
        'created_at': '2026-08-24T08:20:00Z',
      },
    },
  };

  test('читает профиль текущего врача без пациентских заглушек', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me': (statusCode: 200, body: doctorMe()),
    });

    final profile = await RemoteDoctorCabinetRepository(dio).ownProfile();

    expect(profile.fullName, 'Айжан Садыкова');
    expect(profile.doctorId, '11233МК');
    expect(profile.status, 'активен');
    expect(profile.rating, 4.8);
    expect(profile.specialization, 'Кардиолог');
    expect(profile.experience, '10 лет');
    expect(profile.address, 'MedIx Clinic, Алматы');
    expect(profile.phone, '+77010000000');
    expect(adapter.requests.single.path, '/doctors/me');
  });

  test('обновляет ФИО через общий профиль и перечитывает врача', () async {
    final (:dio, :adapter) = cannedDio({
      'PATCH /users/me': (statusCode: 200, body: const <String, Object?>{}),
      '/doctors/me': (
        statusCode: 200,
        body: doctorMe(fullName: 'Айжан Нурлановна'),
      ),
    });
    final repository = RemoteDoctorCabinetRepository(dio);
    final old = await repository.ownProfile();
    adapter.requests.clear();

    final updated = await repository.updateOwnProfile(
      // Остальные поля сервер этого экрана не меняет.
      old.copyWithFullName('Айжан Нурлановна'),
    );

    expect(updated.fullName, 'Айжан Нурлановна');
    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.method, 'PATCH');
    expect(adapter.requests.first.path, '/users/me');
    expect(adapter.requests.first.data, {'full_name': 'Айжан Нурлановна'});
    expect(adapter.requests.last.path, '/doctors/me');
  });

  test('читает и сортирует календарь врача с consultation_id', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me/appointments': (
        statusCode: 200,
        body: [
          appointment(
            id: 'later',
            startsAt: '2026-08-24T10:30:00Z',
            type: 'audio',
            detailed: true,
          ),
          appointment(
            id: 'earlier',
            startsAt: '2026-08-24T07:30:00Z',
            detailed: true,
          ),
        ],
      ),
    });
    final day = DateTime(2026, 8, 24);

    final result = await RemoteDoctorCabinetRepository(
      dio,
    ).appointmentsForDay(day);

    expect(result.map((item) => item.id), ['earlier', 'later']);
    expect(result.first.patientId, patientId);
    expect(result.first.consultationId, consultationId);
    expect(result.first.kind, AppointmentKind.videoCall);
    expect(result.last.kind, AppointmentKind.audioCall);
    expect(result.first.conclusion, 'Состояние стабильное');
    expect(adapter.requests.single.queryParameters, {
      'from': day.toUtc().toIso8601String(),
      'to': day
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1))
          .toUtc()
          .toIso8601String(),
      'limit': 100,
    });
  });

  test('история запрашивает только завершённые записи', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me/appointments': (
        statusCode: 200,
        body: [appointment(type: 'in_person')],
      ),
    });
    final from = DateTime.utc(2026, 8, 1);
    final to = DateTime.utc(2026, 8, 31);

    final result = await RemoteDoctorCabinetRepository(
      dio,
    ).pastAppointments(from: from, to: to);

    expect(result.single.kind, AppointmentKind.inPerson);
    expect(adapter.requests.single.queryParameters['status'], 'completed');
  });

  test('собирает карточку пациента из детали и свежих замеров', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me/appointments/$appointmentId': (
        statusCode: 200,
        body: appointment(detailed: true),
      ),
      '/doctors/me/patients/$patientId/medical-records': (
        statusCode: 200,
        body: [
          measurement('height', 168, '2026-08-20T08:00:00Z'),
          measurement('height', 170, '2026-08-23T08:00:00Z'),
          measurement('weight', 77.4, '2026-08-23T08:00:00Z'),
        ],
      ),
    });

    final patient = await RemoteDoctorCabinetRepository(
      dio,
    ).patient(appointmentId);

    expect(patient.id, patientId);
    expect(patient.fullName, 'Дархан Аркалыков');
    expect(patient.age, 25);
    expect(patient.heightCm, 170);
    expect(patient.weightKg, 77);
    expect(patient.appointment?.consultationId, consultationId);
    expect(patient.conclusion, 'Состояние стабильное');
    expect(patient.analyses, isEmpty);
    expect(adapter.requests, hasLength(2));
  });

  test('профиль из грида находит ближайшую запись по patient id', () async {
    final secondAppointment = '00000000-0000-0000-0000-000000000021';
    final (:dio, :adapter) = cannedDio({
      '/doctors/me/appointments/$patientId': (
        statusCode: 404,
        body: {'detail': 'Запись не найдена'},
      ),
      '/doctors/me/appointments': (
        statusCode: 200,
        body: [appointment(id: secondAppointment)],
      ),
      '/doctors/me/appointments/$secondAppointment': (
        statusCode: 200,
        body: appointment(id: secondAppointment, detailed: true),
      ),
      '/doctors/me/patients/$patientId/medical-records': (
        statusCode: 200,
        body: const <Object>[],
      ),
    });

    final patient = await RemoteDoctorCabinetRepository(dio).patient(patientId);

    expect(patient.appointment?.id, secondAppointment);
    expect(adapter.requests.map((request) => request.path), [
      '/doctors/me/appointments/$patientId',
      '/doctors/me/appointments',
      '/doctors/me/appointments/$secondAppointment',
      '/doctors/me/patients/$patientId/medical-records',
    ]);
  });

  test('дедуплицирует постоянных пациентов из записей', () async {
    final (:dio, adapter: _) = cannedDio({
      '/doctors/me/appointments': (
        statusCode: 200,
        body: [
          appointment(id: 'a1'),
          appointment(id: 'a2'),
          appointment(id: 'a3', patient: 'patient-2', fullName: 'Пациент 2'),
        ],
      ),
    });

    final patients = await RemoteDoctorCabinetRepository(dio).regularPatients();

    expect(patients, hasLength(2));
    expect(patients.map((item) => item.id), [patientId, 'patient-2']);
  });

  test('загружает записи врача до последней страницы', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            final offset = options.queryParameters['offset'] as int? ?? 0;
            final body = offset == 0
                ? [
                    for (var i = 0; i < 100; i++)
                      appointment(id: 'a$i', patient: 'p$i'),
                  ]
                : [
                    appointment(
                      id: 'last',
                      patient: 'last-patient',
                      fullName: 'Последний пациент',
                    ),
                  ];
            handler.resolve(Response(requestOptions: options, data: body));
          },
        ),
      );

    final patients = await RemoteDoctorCabinetRepository(dio).regularPatients();

    expect(patients, hasLength(101));
    expect(requests, hasLength(2));
    expect(requests.first.queryParameters.containsKey('offset'), isFalse);
    expect(requests.last.queryParameters['offset'], 100);
  });

  test('читает собственный сертификат и отзывы через id врача', () async {
    final (:dio, :adapter) = cannedDio({
      '/doctors/me': (statusCode: 200, body: doctorMe()),
      '/doctors/$doctorId/reviews': (
        statusCode: 200,
        body: [
          {
            'id': 'review-1',
            'doctor_id': doctorId,
            'author_id': patientId,
            'author_name': 'Дархан А.',
            'consultation_id': consultationId,
            'rating': 5,
            'body': 'Всё отлично',
            'created_at': '2026-08-24T09:00:00Z',
          },
        ],
      ),
    });
    final repository = RemoteDoctorCabinetRepository(dio);

    final certificates = await repository.certificates();
    final reviews = await repository.ownReviews();

    expect(certificates.single.fileName, 'Документ 1.pdf');
    expect(reviews.single.authorName, 'Дархан А.');
    expect(reviews.single.rating, 5);
    expect(reviews.single.text, 'Всё отлично');
    expect(adapter.requests.last.path, '/doctors/$doctorId/reviews');
  });

  test('собирает врачебный чат из консультации, записи и сообщений', () async {
    final (:dio, adapter: _) = cannedDio({
      '/users/me': (statusCode: 200, body: {'id': doctorId}),
      '/consultations': (
        statusCode: 200,
        body: [
          {
            'id': consultationId,
            'appointment_id': appointmentId,
            'status': 'in_progress',
            'started_at': '2026-08-24T07:30:00Z',
            'ended_at': null,
          },
        ],
      ),
      '/doctors/me/appointments/$appointmentId': (
        statusCode: 200,
        body: appointment(detailed: true),
      ),
      '/consultations/$consultationId/messages': (
        statusCode: 200,
        body: [
          {
            'id': 'message-1',
            'consultation_id': consultationId,
            'sender_id': patientId,
            'body': 'Добрый день',
            'created_at': '2026-08-24T07:35:00Z',
          },
        ],
      ),
    });

    final threads = await RemoteDoctorCabinetRepository(dio).patientChats();

    expect(threads.single.id, consultationId);
    expect(threads.single.patientName, 'Дархан Аркалыков');
    expect(threads.single.lastMessage, 'Добрый день');
    expect(threads.single.lastMessageIsMine, isFalse);
  });
}

Map<String, Object?> measurement(String kind, num value, String createdAt) => {
  'id': '$kind-$createdAt',
  'family_member_id': null,
  'appointment_id': null,
  'record_type': 'measurement',
  'payload': {
    'kind': kind,
    'value': value,
    'unit': kind == 'height' ? 'cm' : 'kg',
    'measured_at': createdAt,
  },
  'created_by': null,
  'superseded_by': null,
  'created_at': createdAt,
};

extension on DoctorOwnProfile {
  /// Тесту важна только смена ФИО; extension сохраняет сборку сущности рядом
  /// с тестом и не добавляет в production-модель лишний copyWith.
  DoctorOwnProfile copyWithFullName(String fullName) => DoctorOwnProfile(
    fullName: fullName,
    doctorId: doctorId,
    status: status,
    rating: rating,
    specialization: specialization,
    experience: experience,
    category: category,
    address: address,
    onlineConsultations: onlineConsultations,
    phone: phone,
    email: email,
  );
}
