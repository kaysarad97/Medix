import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';

abstract interface class DoctorsRepository {
  Future<Doctor> doctor(String id);

  Future<DoctorSchedule> schedule(String doctorId);

  Future<List<DoctorReview>> reviews(String doctorId);

  /// Запись, открытая с главной. Экран «Ваша запись» показывает её же.
  Future<Appointment> appointment(String id);

  /// Специальности для грида «Все Врачи» на экране поиска.
  Future<List<DoctorSpecialty>> specialties();

  /// «Мои Врачи» — те, у кого пользователь уже был.
  Future<List<MyDoctor>> myDoctors();

  /// Результаты поиска по специальности или свободному запросу.
  Future<List<Doctor>> search(String query);
}

/// Заглушка на время разработки бэкенда. Данные — с макетов
/// `design/Профиль врача + запись.png` и `design/Ваша Запись.png`.
class MockDoctorsRepository implements DoctorsRepository {
  const MockDoctorsRepository();

  /// Задержка как у заглушки главной: экран должен успеть показать
  /// состояние загрузки.
  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<Doctor> doctor(String id) async {
    await Future<void>.delayed(_latency);
    return Doctor(
      id: id,
      fullName: 'Имя Фамилия',
      specialty: 'Гастроэнтеролог',
      clinic: 'Название клиники, улица, город',
      rating: 4.5,
      experienceYears: 10,
      city: 'Алматы',
    );
  }

  @override
  Future<DoctorSchedule> schedule(String doctorId) async {
    await Future<void>.delayed(_latency);
    return DoctorSchedule(days: mockWeek);
  }

  @override
  Future<List<DoctorReview>> reviews(String doctorId) async {
    await Future<void>.delayed(_latency);
    return const [
      DoctorReview(
        id: 'r1',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text:
            'Временный текст отзыва о враче. Скоро здесь будут настоящие '
            'отзывы от настоящих пациентов, которые проходили консультацию '
            'или лечение у этого врача. Мы работаем только с '
            'квалифицированными специалистами с хорошим рейтингом.',
      ),
      DoctorReview(
        id: 'r2',
        authorName: 'Пользователь 2',
        rating: 5,
        text:
            'Второй временный отзыв — карусель на макете листается, значит '
            'записей должно быть больше одной.',
      ),
      DoctorReview(
        id: 'r3',
        authorName: 'Пользователь 3',
        rating: 4,
        text: 'Третий временный отзыв: на макете под карточкой три точки.',
      ),
    ];
  }

  @override
  Future<Appointment> appointment(String id) async {
    await Future<void>.delayed(_latency);
    return Appointment(
      id: id,
      specialty: 'Гастроэнтеролог',
      kind: AppointmentKind.audioCall,
      startsAt: DateTime(2026, 7, 10, 13, 30),
      doctorId: 'd1',
    );
  }

  @override
  Future<List<DoctorSpecialty>> specialties() async {
    await Future<void>.delayed(_latency);
    return mockSpecialties;
  }

  @override
  Future<List<MyDoctor>> myDoctors() async {
    await Future<void>.delayed(_latency);
    return mockMyDoctors;
  }

  @override
  Future<List<Doctor>> search(String query) async {
    await Future<void>.delayed(_latency);
    // Настоящего поиска нет — бэкенда тоже нет. Заглушка всегда отдаёт один
    // и тот же набор результатов, только подставляет запрос специальностью,
    // как на `design/Поиск врача результаты - Gold.png`.
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

  /// Грид «Все Врачи»: `design/Поиск врача - спецализация.png`.
  static const List<DoctorSpecialty> mockSpecialties = [
    DoctorSpecialty(id: 's1', title: 'Офтальмолог', doctorCount: 10),
    DoctorSpecialty(id: 's2', title: 'Косметолог', doctorCount: 10),
    DoctorSpecialty(id: 's3', title: 'Кардиолог', doctorCount: 10),
    DoctorSpecialty(id: 's4', title: 'Невролог', doctorCount: 10),
    DoctorSpecialty(id: 's5', title: 'Педиатр', doctorCount: 10),
    DoctorSpecialty(id: 's6', title: 'Аллерголог', doctorCount: 10),
    DoctorSpecialty(id: 's7', title: 'Терапевт', doctorCount: 10),
    DoctorSpecialty(id: 's8', title: 'Психолог', doctorCount: 10),
  ];

  /// «Мои Врачи» на том же экране.
  static const List<MyDoctor> mockMyDoctors = [
    MyDoctor(id: 'd1', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    MyDoctor(id: 'd2', specialty: 'Терапевт', fullName: 'Ф. Имя Отчество'),
    MyDoctor(id: 'd3', specialty: 'Педиатр', fullName: 'Ф. Имя Отчество'),
  ];

  /// Неделя из макета: понедельник — воскресенье, выходные недоступны.
  ///
  /// РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. На макете подписан «Июль, 2026»,
  /// а числа под днями идут 18…24 с понедельника. В июле 2026 года 18-е —
  /// суббота, такой недели не существует. Числа взяты настоящие: 20…26.
  /// Вёрстка от этого не меняется, ширина колонок одинаковая.
  static final List<ScheduleDay> mockWeek = [
    for (var day = 20; day <= 26; day++)
      ScheduleDay(
        date: DateTime(2026, 7, day),
        slots: day >= 25
            ? const []
            : [
                DateTime(2026, 7, day, 9, 30),
                DateTime(2026, 7, day, 10, 30),
                DateTime(2026, 7, day, 12, 30),
                DateTime(2026, 7, day, 15, 30),
              ],
      ),
  ];
}
