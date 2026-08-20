import '../../../../shared/models/appointment.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/entities/doctor_appointment.dart';
import '../../domain/entities/doctor_own_profile.dart';
import '../../domain/entities/doctor_own_review.dart';
import '../../domain/entities/regular_patient.dart';
import '../../domain/entities/work_analytics.dart';

abstract interface class DoctorCabinetRepository {
  /// «Предстоящие записи» на главной — ближайшие записи безотносительно дня.
  Future<List<DoctorAppointment>> upcomingAppointments();

  /// Записи одного дня — календарь сам раскладывает их по [DoctorDayPeriod].
  Future<List<DoctorAppointment>> appointmentsForDay(DateTime day);

  /// «Постоянные пациенты» на главной.
  Future<List<RegularPatient>> regularPatients();

  /// «Ваш Профиль».
  Future<DoctorOwnProfile> ownProfile();

  /// «Ваши сертификаты».
  Future<List<Certificate>> certificates();

  /// «Отзывы о Вас».
  Future<List<DoctorOwnReview>> ownReviews();

  /// Прошедшие записи за промежуток — «История записей».
  Future<List<DoctorAppointment>> pastAppointments({
    required DateTime from,
    required DateTime to,
  });

  /// Одна прошедшая запись с заключением — «О прошлой записи».
  Future<DoctorAppointment> pastAppointment(String id);

  /// «Аналитика Работы» — неделя и месяц разом.
  Future<DoctorWorkAnalytics> workAnalytics();
}

/// Заглушка на время разработки бэкенда — кабинета врача на сервере пока
/// нет вовсе. Данные — с макетов `design/.../Главная - в.ф.png` и
/// `design/.../Календарь.png`.
class MockDoctorCabinetRepository implements DoctorCabinetRepository {
  const MockDoctorCabinetRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<List<DoctorAppointment>> upcomingAppointments() async {
    await Future<void>.delayed(_latency);
    final today = DateTime.now();
    return [
      DoctorAppointment(
        id: 'a1',
        patientName: 'Пациент Имя Фамилия',
        kind: AppointmentKind.videoCall,
        startsAt: DateTime(today.year, today.month, today.day + 1, 10, 30),
      ),
      DoctorAppointment(
        id: 'a2',
        patientName: 'Пациент Имя Фамилия',
        kind: AppointmentKind.videoCall,
        startsAt: DateTime(today.year, today.month, today.day + 3, 14, 30),
      ),
    ];
  }

  @override
  Future<List<DoctorAppointment>> appointmentsForDay(DateTime day) async {
    await Future<void>.delayed(_latency);
    return [
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
  }

  @override
  Future<List<RegularPatient>> regularPatients() async {
    await Future<void>.delayed(_latency);
    return const [
      RegularPatient(id: 'p1', fullName: 'Ф. Имя Отчество'),
      RegularPatient(id: 'p2', fullName: 'Ф. Имя Отчество'),
      RegularPatient(id: 'p3', fullName: 'Ф. Имя Отчество'),
      RegularPatient(id: 'p4', fullName: 'Ф. Имя Отчество'),
    ];
  }

  @override
  Future<DoctorOwnProfile> ownProfile() async {
    await Future<void>.delayed(_latency);
    return const DoctorOwnProfile(
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
  }

  @override
  Future<List<Certificate>> certificates() async {
    await Future<void>.delayed(_latency);
    return const [
      Certificate(id: 'c1', fileName: 'Документ 1.pdf'),
      Certificate(id: 'c2', fileName: 'Документ 2.pdf'),
      Certificate(id: 'c3', fileName: 'Документ 3.pdf'),
      Certificate(id: 'c4', fileName: 'Документ 4.pdf'),
      Certificate(id: 'c5', fileName: 'Документ 5.pdf'),
      Certificate(id: 'c6', fileName: 'Документ 6.pdf'),
    ];
  }

  @override
  Future<List<DoctorOwnReview>> ownReviews() async {
    await Future<void>.delayed(_latency);
    const text =
        'Временный текст отзыва о враче. Скоро здесь будут настоящие '
        'отзывы от настоящих пациентов, которые проходили консультацию '
        'или лечение у этого врача. Мы работаем только с '
        'квалифицированными специалистами с хорошим рейтингом.';
    return const [
      DoctorOwnReview(
        id: 'r1',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text: text,
      ),
      DoctorOwnReview(
        id: 'r2',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text: text,
      ),
      DoctorOwnReview(
        id: 'r3',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text: text,
      ),
      DoctorOwnReview(
        id: 'r4',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text: text,
      ),
      DoctorOwnReview(
        id: 'r5',
        authorName: 'Пользователь 1',
        rating: 4.5,
        text: text,
      ),
    ];
  }

  /// Четыре записи на промежуток, как в макете. День берётся от начала
  /// промежутка, чтобы список менялся при перелистывании недели, — иначе
  /// пейджер выглядел бы сломанным.
  @override
  Future<List<DoctorAppointment>> pastAppointments({
    required DateTime from,
    required DateTime to,
  }) async {
    await Future<void>.delayed(_latency);
    return [for (var i = 0; i < 4; i++) _past('h${from.day}-$i', from, i)];
  }

  @override
  Future<DoctorAppointment> pastAppointment(String id) async {
    await Future<void>.delayed(_latency);
    final today = DateTime.now();
    // Заключения нет: в макете на его месте стоит объяснение, почему поле
    // пустое, — значит, это и есть состояние по умолчанию.
    return _past(id, today.subtract(const Duration(days: 7)), 0);
  }

  /// Строка записи из макета: аудио-звонок, «Имя Фамилия», приём почти
  /// полтора часа.
  static DoctorAppointment _past(String id, DateTime day, int index) {
    final start = DateTime(day.year, day.month, day.day + index, 13, 30);
    return DoctorAppointment(
      id: id,
      patientName: 'Имя Фамилия',
      kind: AppointmentKind.audioCall,
      startsAt: start,
      endsAt: start.add(const Duration(minutes: 77)),
      patientAvatarAsset: MedixAvatars.all[index % MedixAvatars.all.length],
    );
  }

  @override
  Future<DoctorWorkAnalytics> workAnalytics() async {
    await Future<void>.delayed(_latency);
    final today = DateTime.now();
    final monday = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1));

    return DoctorWorkAnalytics(
      week: DoctorWeekAnalytics(
        from: monday,
        to: monday.add(const Duration(days: 6)),
        // Столбики с макета: понедельник пустой, среда самая высокая.
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
        month: DateTime(today.year, today.month),
        // Ломаная с макета: растёт к 20-му, проседает к 25-му и снова
        // идёт вверх. Тридцать значений — столько же дней на оси.
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
}
