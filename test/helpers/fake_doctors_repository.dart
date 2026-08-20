import 'package:medix/features/telemedicine/data/repositories/doctors_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_review.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/shared/models/appointment.dart';
import 'package:medix/shared/models/doctor_specialty.dart';
import 'package:medix/shared/models/my_doctor.dart';

/// Те же данные, что у [MockDoctorsRepository], но без задержки.
///
/// Задержка в заглушке сделана через `Future.delayed`, а таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeDoctorsRepository implements DoctorsRepository {
  const FakeDoctorsRepository({this.appointmentSubscriberPrice = 10000});

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

  static final List<({String id, ScheduleSlot slot})> rescheduled = [];

  @override
  Future<Doctor> doctor(String id) async => doctor1;

  /// Неделя от понедельника 20 июля 2026 — та же, что была зашита в
  /// заглушке до перехода на текущую дату. Здесь она неподвижна намеренно:
  /// расписание в приложении отсчитывается от сегодняшнего дня, и без
  /// фиксированной точки эталоны расходились бы каждые сутки.
  static final DoctorSchedule fixedWeek = DoctorSchedule(
    days: MockDoctorsRepository.weekFrom(DateTime(2026, 7, 20)),
  );

  /// [from] намеренно игнорируется: тестам нужна одна и та же лента, на
  /// какой бы неделе ни стоял экран.
  @override
  Future<DoctorSchedule> schedule(String doctorId, {DateTime? from}) async =>
      fixedWeek;

  @override
  Future<List<DoctorReview>> reviews(String doctorId) async => const [review1];

  /// Скидка на записи этой заглушки. Скидку считает сервер, а не клиент, —
  /// поэтому «есть подписка» и «нет подписки» в тестах различаются данными
  /// записи, а не тарифом в профиле.
  final int? appointmentSubscriberPrice;

  @override
  Future<Appointment> appointment(String id) async => Appointment(
    id: id,
    specialty: 'Гастроэнтеролог',
    kind: AppointmentKind.audioCall,
    startsAt: DateTime(2026, 7, 10, 13, 30),
    doctorId: 'd1',
    basePrice: 15000,
    subscriberPrice: appointmentSubscriberPrice,
  );

  @override
  Future<List<Appointment>> appointments({bool upcoming = false}) async => [
    await appointment('a1'),
  ];

  @override
  Future<Appointment> reschedule(String id, ScheduleSlot newSlot) async => () {
    rescheduled.add((id: id, slot: newSlot));
    return Appointment(
      id: id,
      specialty: 'Гастроэнтеролог',
      kind: AppointmentKind.audioCall,
      startsAt: newSlot.startsAt,
      doctorId: 'd1',
    );
  }();

  @override
  Future<Appointment> cancel(String id) async => Appointment(
    id: id,
    specialty: 'Гастроэнтеролог',
    kind: AppointmentKind.audioCall,
    startsAt: DateTime(2026, 7, 10, 13, 30),
    doctorId: 'd1',
    status: AppointmentStatus.cancelled,
  );

  /// Что ушло в [book] — форме записи проверять больше нечего.
  static final List<({ScheduleSlot slot, AppointmentKind kind})> booked = [];

  @override
  Future<Appointment> book({
    required Doctor doctor,
    required ScheduleSlot slot,
    required AppointmentKind kind,
    String? familyMemberId,
  }) async {
    booked.add((slot: slot, kind: kind));
    return Appointment(
      id: 'a1',
      specialty: doctor.specialty,
      kind: kind,
      startsAt: slot.startsAt,
      doctorId: doctor.id,
    );
  }

  @override
  Future<List<DoctorSpecialty>> specialties() async =>
      MockDoctorsRepository.mockSpecialties;

  @override
  Future<List<MyDoctor>> myDoctors() async =>
      MockDoctorsRepository.mockMyDoctors;

  @override
  Future<List<Doctor>> search(String query) async {
    final specialty = query.trim().isEmpty ? 'Гастроэнтеролог' : query.trim();
    return [
      for (final id in const ['d1', 'd4', 'd5', 'd6'])
        Doctor(
          id: id,
          fullName: 'Имя Фамилия',
          specialty: specialty,
          clinic: 'Название клиники, улица, город',
          rating: 4.5,
          experienceYears: 10,
          reviewsCount: 100,
          price: 10000,
          priceBeforeDiscount: 15000,
        ),
    ];
  }
}
