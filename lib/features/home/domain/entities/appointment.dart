/// Формат приёма.
enum AppointmentKind {
  videoCall('Видео-звонок'),
  audioCall('Аудио-звонок'),
  chat('Чат'),
  inPerson('Очный приём');

  const AppointmentKind(this.label);

  final String label;
}

/// Предстоящая запись к врачу.
class Appointment {
  const Appointment({
    required this.id,
    required this.specialty,
    required this.kind,
    required this.startsAt,
  });

  final String id;
  final String specialty;
  final AppointmentKind kind;
  final DateTime startsAt;

  /// Дата в пилюле справа: «13.08».
  String get shortDate =>
      '${startsAt.day.toString().padLeft(2, '0')}.'
      '${startsAt.month.toString().padLeft(2, '0')}';
}
