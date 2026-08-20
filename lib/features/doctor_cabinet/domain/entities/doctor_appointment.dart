import '../../../../core/utils/ru_dates.dart';
import '../../../../shared/models/appointment.dart';

/// Часть дня, в которую попадает запись — для группировки в календаре
/// врача (`design/.../Календарь.png`: «Утренние/Дневные/Вечерние записи»).
///
/// Границы в макете не размечены — там всего четыре занятых слота (10:30,
/// 11:30 утром; 14:30, 15:30 днём) и одна пустая вечерняя корзина. Взято на
/// глаз, уточнить у дизайнера при случае.
enum DoctorDayPeriod {
  morning,
  afternoon,
  evening;

  static DoctorDayPeriod of(DateTime time) {
    if (time.hour < 12) return DoctorDayPeriod.morning;
    if (time.hour < 18) return DoctorDayPeriod.afternoon;
    return DoctorDayPeriod.evening;
  }
}

/// Запись пациента к врачу — со стороны врача.
///
/// Не переиспользует [Appointment]: та сущность про пациентскую сторону
/// записи (специальность, цена, id врача), а здесь ровно наоборот — нужно
/// имя пациента, а специальность врача и цена не нужны вовсе. Общее у обеих
/// сущностей — только [AppointmentKind], он и переехал в `shared/`.
class DoctorAppointment {
  const DoctorAppointment({
    required this.id,
    required this.patientName,
    required this.kind,
    required this.startsAt,
    this.patientAvatarAsset,
  });

  final String id;
  final String patientName;
  final AppointmentKind kind;
  final DateTime startsAt;

  /// Аватар пациента в строке календаря. На главной не используется.
  final String? patientAvatarAsset;

  /// «13.08» — пилюля в карточке «Предстоящие записи» на главной.
  String get shortDate => RuDates.dayMonth(startsAt);

  /// «10:30» — пилюля в строке календаря.
  String get timeLabel => RuDates.time(startsAt);

  DoctorDayPeriod get period => DoctorDayPeriod.of(startsAt);
}
