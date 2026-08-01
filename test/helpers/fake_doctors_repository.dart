import 'package:medix/features/telemedicine/data/repositories/doctors_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_review.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/shared/models/appointment.dart';

/// Те же данные, что у [MockDoctorsRepository], но без задержки.
///
/// Задержка в заглушке сделана через `Future.delayed`, а таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeDoctorsRepository implements DoctorsRepository {
  const FakeDoctorsRepository();

  static const doctor1 = Doctor(
    id: 'd1',
    fullName: 'Имя Фамилия',
    specialty: 'Гастроэнтеролог',
    clinic: 'Название клиники, улица, город',
    rating: 4.5,
    experienceYears: 10,
    city: 'Алматы',
  );

  static const review1 = DoctorReview(
    id: 'r1',
    authorName: 'Пользователь 1',
    rating: 4.5,
    text:
        'Временный текст отзыва о враче. Скоро здесь будут настоящие отзывы '
        'от настоящих пациентов, которые проходили консультацию или лечение '
        'у этого врача. Мы работаем только с квалифицированными '
        'специалистами с хорошим рейтингом.',
  );

  @override
  Future<Doctor> doctor(String id) async => doctor1;

  @override
  Future<DoctorSchedule> schedule(String doctorId) async =>
      DoctorSchedule(days: MockDoctorsRepository.mockWeek);

  @override
  Future<List<DoctorReview>> reviews(String doctorId) async => const [review1];

  @override
  Future<Appointment> appointment(String id) async => Appointment(
    id: id,
    specialty: 'Гастроэнтеролог',
    kind: AppointmentKind.audioCall,
    startsAt: DateTime(2026, 7, 10, 13, 30),
    doctorId: 'd1',
  );
}
