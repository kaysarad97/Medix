import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/utils/ru_dates.dart';
import 'package:medix/features/telemedicine/data/repositories/doctors_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/shared/models/appointment.dart';

void main() {
  group('чип стажа склоняется', () {
    Doctor withYears(int years) => Doctor(
      id: 'd1',
      fullName: 'Имя Фамилия',
      specialty: 'Гастроэнтеролог',
      clinic: 'Клиника',
      rating: 4.5,
      experienceYears: years,
    );

    const cases = <int, String>{
      1: 'Стаж 1 год',
      2: 'Стаж 2 года',
      4: 'Стаж 4 года',
      5: 'Стаж 5 лет',
      10: 'Стаж 10 лет',
      // 11–14 — исключение: «одиннадцать лет», а не «одиннадцать год».
      11: 'Стаж 11 лет',
      12: 'Стаж 12 лет',
      14: 'Стаж 14 лет',
      21: 'Стаж 21 год',
      22: 'Стаж 22 года',
      25: 'Стаж 25 лет',
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () {
        expect(withYears(entry.key).experienceLabel, entry.value);
      });
    }
  });

  test('рейтинг показывается с одним знаком', () {
    final doctor = Doctor(
      id: 'd1',
      fullName: 'Имя Фамилия',
      specialty: 'Гастроэнтеролог',
      clinic: 'Клиника',
      rating: 4,
      experienceYears: 10,
    );
    expect(doctor.ratingLabel, '4.0');
  });

  group('даты по-русски', () {
    test('месяц и год', () {
      expect(RuDates.monthAndYear(DateTime(2026, 7, 20)), 'Июль, 2026');
    });

    test('день недели', () {
      expect(RuDates.weekdayShort(DateTime(2026, 7, 20)), 'Пн');
      expect(RuDates.weekdayShort(DateTime(2026, 7, 26)), 'Вс');
    });

    test('час без ведущего нуля, минуты с ним', () {
      expect(RuDates.time(DateTime(2026, 7, 20, 9, 30)), '9:30');
      expect(RuDates.time(DateTime(2026, 7, 20, 13, 5)), '13:05');
    });

    test('день и месяц с ведущими нулями', () {
      expect(RuDates.dayMonth(DateTime(2026, 7, 10)), '10.07');
      expect(RuDates.dayMonth(DateTime(2026, 12, 5)), '05.12');
    });
  });

  test('запись отдаёт дату и время строкой из макета', () {
    final appointment = Appointment(
      id: 'a1',
      specialty: 'Гастроэнтеролог',
      kind: AppointmentKind.audioCall,
      startsAt: DateTime(2026, 7, 10, 13, 30),
    );
    expect(appointment.dayMonthTime, '10.07, 13:30');
    expect(appointment.shortDate, '10.07');
  });

  group('расписание', () {
    final week = [
      ScheduleDay(date: DateTime(2026, 7, 25), slots: const []),
      ScheduleDay(
        date: DateTime(2026, 7, 26),
        slots: [ScheduleSlot(id: 's1', startsAt: DateTime(2026, 7, 26, 9, 30))],
      ),
    ];

    test('день без слотов недоступен', () {
      expect(week.first.isAvailable, isFalse);
      expect(week.first.firstSlot, isNull);
    });

    test('первый доступный день пропускает занятые', () {
      final schedule = DoctorSchedule(days: week);
      expect(schedule.firstAvailable, week[1]);
    });

    test('заголовок месяца берётся по первому дню ленты', () {
      expect(DoctorSchedule(days: week).monthLabel, 'Июль, 2026');
    });
  });

  group('лента расписания строится от переданного дня', () {
    test('семь дней подряд начиная с сегодняшнего', () {
      final days = MockDoctorsRepository.weekFrom(DateTime(2026, 8, 12, 8));

      expect(days.length, 7);
      expect(days.first.date, DateTime(2026, 8, 12));
      expect(days.last.date, DateTime(2026, 8, 18));
    });

    test('переход через конец месяца считается верно', () {
      final days = MockDoctorsRepository.weekFrom(DateTime(2026, 8, 30));

      expect(days.last.date, DateTime(2026, 9, 5));
    });

    test('выходные остаются без слотов', () {
      // 15 и 16 августа 2026 — суббота и воскресенье.
      final days = MockDoctorsRepository.weekFrom(DateTime(2026, 8, 12, 8));
      final weekend = days.where(
        (d) =>
            d.date == DateTime(2026, 8, 15) || d.date == DateTime(2026, 8, 16),
      );

      expect(weekend, hasLength(2));
      expect(weekend.every((d) => d.isAvailable), isFalse);
    });

    test('время, которое уже прошло, в первый день не попадает', () {
      // Полдень: 9:30 и 10:30 позади, 12:30 и 15:30 ещё впереди.
      final days = MockDoctorsRepository.weekFrom(DateTime(2026, 8, 12, 12));

      expect(days.first.slots.map((s) => s.startsAt), [
        DateTime(2026, 8, 12, 12, 30),
        DateTime(2026, 8, 12, 15, 30),
      ]);
      // Следующий день урезать нечего.
      expect(days[1].slots.first.startsAt, DateTime(2026, 8, 13, 9, 30));
    });

    test('день, в котором приём уже кончился, недоступен', () {
      final days = MockDoctorsRepository.weekFrom(DateTime(2026, 8, 12, 23));

      expect(days.first.isAvailable, isFalse);
      expect(DoctorSchedule(days: days).firstAvailable, days[1]);
    });
  });
}
