import 'package:medix/features/doctor_cabinet/data/repositories/doctor_cabinet_repository.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/certificate.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_profile.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_review.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/regular_patient.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/work_analytics.dart';
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
}
