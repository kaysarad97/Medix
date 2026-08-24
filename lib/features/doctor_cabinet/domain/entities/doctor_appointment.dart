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
    this.patientId,
    this.consultationId,
    this.patientPhone,
    this.endsAt,
    this.status = AppointmentStatus.unknown,
    this.patientAvatarAsset,
    this.conclusion,
    this.files = const [],
  });

  final String id;
  final String patientName;
  final String? patientId;
  final String? consultationId;

  /// Телефон пациента доступен врачу только в детальной записи очного приёма.
  final String? patientPhone;
  final AppointmentKind kind;
  final DateTime startsAt;

  /// Конец приёма. Есть только у прошедших записей — в «Истории записей»
  /// время подписано промежутком («13:30-14:47»), а в календаре будущих
  /// записей одной точкой начала.
  final DateTime? endsAt;
  final AppointmentStatus status;

  /// Аватар пациента в строке календаря. На главной не используется.
  final String? patientAvatarAsset;

  /// Заключение врача о приёме — «О прошлой записи.png». `null` — врач его
  /// ещё не загрузил, и на месте текста стоит объяснение из макета.
  final String? conclusion;

  /// Файлы консультации, доступные врачу из детальной записи.
  final List<DoctorAppointmentFile> files;

  /// «13.08» — пилюля в карточке «Предстоящие записи» на главной.
  String get shortDate => RuDates.dayMonth(startsAt);

  /// «10:30» — пилюля в строке календаря.
  String get timeLabel => RuDates.time(startsAt);

  /// «10.07, 13:30-14:47» — строка в «Истории записей». Без конца приёма
  /// («10.07, 13:30») — так подписана карточка на «О прошлой записи».
  String get historyLabel {
    final end = endsAt;
    final start = '$shortDate, ${RuDates.hourMinute(startsAt)}';
    return end == null ? start : '$start-${RuDates.hourMinute(end)}';
  }

  DoctorDayPeriod get period => DoctorDayPeriod.of(startsAt);

  DoctorAppointment copyWithConclusion(String value) => DoctorAppointment(
    id: id,
    patientName: patientName,
    patientId: patientId,
    consultationId: consultationId,
    patientPhone: patientPhone,
    kind: kind,
    startsAt: startsAt,
    endsAt: endsAt,
    status: status,
    patientAvatarAsset: patientAvatarAsset,
    conclusion: value,
    files: files,
  );
}

class DoctorAppointmentFile {
  const DoctorAppointmentFile({
    required this.id,
    required this.downloadUrl,
    required this.createdAt,
  });

  final String id;
  final String downloadUrl;
  final DateTime createdAt;
}
