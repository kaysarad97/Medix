import 'package:medix/features/doctor_cabinet/data/repositories/doctor_cabinet_repository.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/admin_request.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/certificate.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_profile.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_review.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_patient.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/patient_chat.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/regular_patient.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/work_analytics.dart';
import 'package:medix/shared/models/analysis_result.dart';
import 'package:medix/shared/models/appointment.dart';
import 'package:medix/shared/models/medix_avatars.dart';

/// Те же данные, что у [MockDoctorCabinetRepository], но без задержки.
///
/// Задержка в заглушке сделана через `Future.delayed`, а таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeDoctorCabinetRepository implements DoctorCabinetRepository {
  const FakeDoctorCabinetRepository();

  @override
  Future<List<DoctorAppointment>> upcomingAppointments() async => [
    DoctorAppointment(
      id: 'a1',
      patientName: 'Пациент Имя Фамилия',
      kind: AppointmentKind.videoCall,
      startsAt: DateTime(2026, 8, 13, 10, 30),
    ),
  ];

  @override
  Future<List<DoctorAppointment>> appointmentsForDay(DateTime day) async => [
    DoctorAppointment(
      id: 'd1',
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.videoCall,
      startsAt: DateTime(day.year, day.month, day.day, 10, 30),
      patientAvatarAsset: MedixAvatars.all[2],
    ),
    DoctorAppointment(
      id: 'd2',
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.videoCall,
      startsAt: DateTime(day.year, day.month, day.day, 11, 30),
      patientAvatarAsset: MedixAvatars.all[5],
    ),
    DoctorAppointment(
      id: 'd3',
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.videoCall,
      startsAt: DateTime(day.year, day.month, day.day, 14, 30),
      patientAvatarAsset: MedixAvatars.all[8],
    ),
    DoctorAppointment(
      id: 'd4',
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.videoCall,
      startsAt: DateTime(day.year, day.month, day.day, 15, 30),
      patientAvatarAsset: MedixAvatars.all[1],
    ),
  ];

  @override
  Future<List<RegularPatient>> regularPatients() async => const [
    RegularPatient(id: 'p1', fullName: 'Ф. Имя Отчество'),
    RegularPatient(id: 'p2', fullName: 'Ф. Имя Отчество'),
    RegularPatient(id: 'p3', fullName: 'Ф. Имя Отчество'),
    RegularPatient(id: 'p4', fullName: 'Ф. Имя Отчество'),
  ];

  @override
  Future<DoctorOwnProfile> ownProfile() async => const DoctorOwnProfile(
    fullName: 'Имя Фамилия',
    doctorId: '11233МК',
    status: 'активен',
    rating: 4.5,
    specialization: '',
    experience: '',
    category: '',
    address: '',
    onlineConsultations: true,
    phone: '+7 700 000 0000',
    email: 'abcefg@mail.com',
  );

  @override
  Future<DoctorOwnProfile> updateOwnProfile(DoctorOwnProfile profile) async =>
      profile;

  @override
  Future<List<Certificate>> certificates() async => const [
    Certificate(id: 'c1', fileName: 'Документ 1.pdf'),
    Certificate(id: 'c2', fileName: 'Документ 2.pdf'),
  ];

  @override
  Future<List<DoctorOwnReview>> ownReviews() async => const [
    DoctorOwnReview(
      id: 'r1',
      authorName: 'Пользователь 1',
      rating: 4.5,
      text: 'Временный текст отзыва о враче.',
    ),
    DoctorOwnReview(
      id: 'r2',
      authorName: 'Пользователь 1',
      rating: 4.5,
      text: 'Временный текст отзыва о враче.',
    ),
  ];

  /// Две прошедшие записи вместо четырёх — тестам хватает, а список
  /// короче читается в ожиданиях.
  @override
  Future<List<DoctorAppointment>> pastAppointments({
    required DateTime from,
    required DateTime to,
  }) async => [
    _past('h1', from),
    _past('h2', from.add(const Duration(days: 1))),
  ];

  @override
  Future<DoctorAppointment> pastAppointment(String id) async =>
      _past(id, DateTime(2026, 7, 10));

  static DoctorAppointment _past(String id, DateTime day) {
    final start = DateTime(day.year, day.month, day.day, 13, 30);
    return DoctorAppointment(
      id: id,
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.audioCall,
      startsAt: start,
      endsAt: start.add(const Duration(minutes: 77)),
      patientAvatarAsset: MedixAvatars.all[2],
    );
  }

  @override
  Future<DoctorWorkAnalytics> workAnalytics() async => DoctorWorkAnalytics(
    week: DoctorWeekAnalytics(
      from: DateTime(2026, 7, 13),
      to: DateTime(2026, 7, 19),
      perDay: const [0, 2, 3, 1, 1, 0, 0],
      stats: const DoctorWorkStats(
        appointments: 7,
        deltaVsUsual: 2,
        averageMinutes: 49,
        ratingDelta: 0.5,
        earningsPercent: 20,
      ),
    ),
    month: DoctorMonthAnalytics(
      month: DateTime(2026, 7),
      perDay: const [
        0,
        0,
        1,
        1,
        0,
        1,
        2,
        1,
        1,
        2,
        2,
        1,
        2,
        3,
        3,
        4,
        4,
        5,
        5,
        6,
        5,
        4,
        3,
        2,
        2,
        3,
        3,
        4,
        5,
        6,
      ],
      stats: const DoctorWorkStats(
        appointments: 15,
        deltaVsUsual: 5,
        averageMinutes: 46,
        ratingDelta: 1.5,
        earningsPercent: 23,
      ),
    ),
  );

  @override
  Future<DoctorPatient> patient(String id) async => DoctorPatient(
    id: id,
    fullName: 'Имя Фамилия',
    heightCm: 170,
    weightKg: 77,
    age: 30,
    avatarAsset: MedixAvatars.all[2],
    appointment: DoctorAppointment(
      id: 'p-$id',
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.audioCall,
      startsAt: DateTime(2026, 7, 21, 10, 30),
    ),
    analyses: [
      for (var i = 0; i < 2; i++)
        AnalysisResult(
          id: 'pa$i',
          name: 'Железо\nв сыворотке',
          value: 24.8,
          unit: 'мкмоль/л',
          referenceLow: 10.7,
          referenceHigh: 32.2,
          takenAt: DateTime(2026, 7, 20 - i),
        ),
    ],
  );

  /// Две переписки: первая непрочитанная, вторая своя — этого хватает,
  /// чтобы проверить и подсветку строки, и приставку «Вы: ».
  @override
  Future<List<PatientChatThread>> patientChats() async => [
    PatientChatThread(
      id: 'pc1',
      patientName: 'Имя Фамилия',
      lastMessage: 'Здравствуйте! Какие анализы мне нужны перед приёмом?',
      lastMessageAt: DateTime(2026, 7, 21, 13, 44),
      lastMessageIsMine: false,
      isRead: false,
      patientAvatarAsset: MedixAvatars.all[2],
    ),
    PatientChatThread(
      id: 'pc2',
      patientName: 'Имя Фамилия',
      lastMessage: 'Спасибо за обращение, на здоровье!',
      lastMessageAt: DateTime(2026, 7, 21, 13, 44),
      lastMessageIsMine: true,
      patientAvatarAsset: MedixAvatars.all[5],
    ),
  ];

  @override
  Future<List<PatientMessage>> patientMessages(String threadId) async => [
    PatientMessage(
      id: '$threadId-1',
      text: 'Здравствуйте! Как Вы себя чувствуете сегодня?',
      isMine: true,
      sentAt: DateTime(2026, 7, 21, 13, 40),
    ),
    PatientMessage(
      id: '$threadId-2',
      text: 'Спасибо, все хорошо!',
      isMine: false,
      sentAt: DateTime(2026, 7, 21, 13, 44),
    ),
  ];

  @override
  Stream<PatientMessage> watchPatientMessages(String threadId) =>
      const Stream.empty();

  @override
  Future<PatientMessage> sendPatientMessage(
    String threadId,
    String text,
  ) async => PatientMessage(
    id: '$threadId-sent',
    text: text,
    isMine: true,
    sentAt: DateTime(2026, 7, 21, 13, 45),
  );

  @override
  Future<void> closePatientChat(String threadId) async {}

  /// Две заявки: одна с ответом, одна без — оба состояния «Ответа от
  /// админа» проверяются на одном фейке.
  @override
  Future<List<AdminRequest>> adminRequests() async => [
    AdminRequest(
      id: 'ar1',
      topic: AdminRequestTopic.reschedule,
      text: _requestText,
      createdAt: DateTime(2026, 8, 10),
      answer: 'Временный текст ответа.',
      answeredAt: DateTime(2026, 8, 10),
    ),
    AdminRequest(
      id: 'ar2',
      topic: AdminRequestTopic.vacation,
      text: _requestText,
      createdAt: DateTime(2026, 8, 10),
    ),
  ];

  /// Тот же текст, что в макете «Мои заявки»: врезка занимает две строки.
  static const String _requestText =
      'Временный текст запроса. Скоро здесь будет описание проблемы, '
      'которое укажет врач.';

  @override
  Future<AdminRequest> adminRequest(String id) async {
    final all = await adminRequests();
    return all.firstWhere(
      (request) => request.id == id,
      orElse: () => all.first,
    );
  }

  @override
  Future<AdminRequest> sendAdminRequest({
    required AdminRequestTopic topic,
    required String text,
  }) async => AdminRequest(
    id: 'ar-sent',
    topic: topic,
    text: text,
    createdAt: DateTime(2026, 8, 10),
  );
}
