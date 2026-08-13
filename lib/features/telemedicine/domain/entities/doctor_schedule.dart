import '../../../../core/utils/ru_dates.dart';

/// Свободное время приёма.
///
/// Не голая дата, как раньше: записываются на конкретный слот по его
/// идентификатору (`POST /appointments {"slot_id": …}`), и время само по
/// себе серверу ничего не говорит.
class ScheduleSlot {
  const ScheduleSlot({required this.id, required this.startsAt});

  final String id;
  final DateTime startsAt;

  /// «9:30».
  String get timeLabel => RuDates.time(startsAt);
}

/// День в недельной ленте расписания.
class ScheduleDay {
  const ScheduleDay({required this.date, required this.slots});

  final DateTime date;

  /// Свободные слоты этого дня. Пусто — день недоступен и рисуется серым
  /// (на макете так выглядят суббота и воскресенье).
  final List<ScheduleSlot> slots;

  bool get isAvailable => slots.isNotEmpty;

  /// «Пн».
  String get weekdayLabel => RuDates.weekdayShort(date);

  /// «18».
  String get dayLabel => date.day.toString();

  /// Ближайшее свободное время этого дня.
  ScheduleSlot? get firstSlot => slots.isEmpty ? null : slots.first;
}

/// Неделя приёма врача: заголовок месяца и семь дней.
class DoctorSchedule {
  const DoctorSchedule({required this.days});

  final List<ScheduleDay> days;

  /// «Июль, 2026» — по первому дню ленты.
  String get monthLabel => RuDates.monthAndYear(days.first.date);

  /// Первый день со свободными слотами. На него встаёт выбор при открытии
  /// экрана: показывать пустую сетку времени незачем.
  ScheduleDay? get firstAvailable {
    for (final day in days) {
      if (day.isAvailable) return day;
    }
    return null;
  }
}
