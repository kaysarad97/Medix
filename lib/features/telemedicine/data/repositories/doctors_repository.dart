import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../domain/entities/doctor.dart';
import '../../domain/entities/doctor_review.dart';
import '../../domain/entities/doctor_schedule.dart';

abstract interface class DoctorsRepository {
  Future<Doctor> doctor(String id);

  /// Лента на семь дней начиная с [from]. Пусто — начиная с сегодняшнего дня.
  /// Через параметр листаются недели вперёд.
  Future<DoctorSchedule> schedule(String doctorId, {DateTime? from});

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
  Future<DoctorSchedule> schedule(String doctorId, {DateTime? from}) async {
    await Future<void>.delayed(_latency);
    return DoctorSchedule(days: weekFrom(from ?? DateTime.now()));
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
      // Совпадает с ценой того же врача в search(): 15 000 без подписки,
      // 10 000 с Gold — как на `design/Предоплата - GOLD.png`.
      basePrice: 15000,
      goldPrice: 10000,
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

  /// Семь дней подряд начиная с [from]: столько же колонок, сколько в макете.
  ///
  /// Отсчёт идёт от переданного дня, а не от понедельника его недели. Это
  /// экран записи: дни, которые уже прошли, занимают место и выбрать их
  /// нельзя. По той же причине у первого дня отбрасывается время, которое
  /// уже наступило.
  ///
  /// Параметр, а не `DateTime.now()` внутри: тестам нужна неподвижная
  /// неделя, иначе эталоны менялись бы каждый день.
  ///
  /// РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. На макете подписан «Июль, 2026»,
  /// а числа под днями идут 18…24 с понедельника. В июле 2026 года 18-е —
  /// суббота, такой недели не существует. Вёрстка от настоящих чисел не
  /// меняется: ширина колонок одинаковая.
  static List<ScheduleDay> weekFrom(DateTime from) {
    final first = DateTime(from.year, from.month, from.day);
    return [
      for (var i = 0; i < 7; i++)
        _scheduleDay(
          // Через конструктор, а не add(Duration): так переход через конец
          // месяца считает сам DateTime.
          DateTime(first.year, first.month, first.day + i),
          notBefore: from,
        ),
    ];
  }

  /// Часы приёма одинаковы во все будни — как на макете. Выходные пустые:
  /// в макете суббота и воскресенье серые.
  static const List<({int hour, int minute})> _workingHours = [
    (hour: 9, minute: 30),
    (hour: 10, minute: 30),
    (hour: 12, minute: 30),
    (hour: 15, minute: 30),
  ];

  static ScheduleDay _scheduleDay(
    DateTime date, {
    required DateTime notBefore,
  }) {
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    final slots = <DateTime>[];
    if (!isWeekend) {
      for (final time in _workingHours) {
        final slot = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (slot.isAfter(notBefore)) slots.add(slot);
      }
    }

    return ScheduleDay(date: date, slots: slots);
  }
}
