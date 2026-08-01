import '../../core/utils/ru_dates.dart';

/// Формат приёма.
enum AppointmentKind {
  videoCall('Видео-звонок'),
  audioCall('Аудио-звонок'),
  chat('Чат'),
  inPerson('Очный приём');

  const AppointmentKind(this.label);

  final String label;
}

/// Запись к врачу.
///
/// Лежит в `shared/`, а не в фиче: её показывают и главная («Предстоящие
/// записи»), и телемедицина (экран «Ваша запись»).
class Appointment {
  const Appointment({
    required this.id,
    required this.specialty,
    required this.kind,
    required this.startsAt,
    this.doctorId,
  });

  final String id;
  final String specialty;
  final AppointmentKind kind;
  final DateTime startsAt;

  /// Врач, к которому запись. У моков главной пусто.
  final String? doctorId;

  /// Дата в пилюле справа на главной: «13.08».
  String get shortDate => RuDates.dayMonth(startsAt);

  /// Дата и время в карточке записи: «10.07, 13:30».
  String get dayMonthTime =>
      '${RuDates.dayMonth(startsAt)}, ${RuDates.time(startsAt)}';
}
