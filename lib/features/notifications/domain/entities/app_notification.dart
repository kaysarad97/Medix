import '../../../../core/utils/ru_dates.dart';

/// О чём уведомление.
///
/// Ровно два вида — столько в макете `design/Нотификации.png`, и на них же
/// разбиты вкладки: «Расписание» и «Сообщения от врачей».
enum NotificationKind {
  /// «Ваша запись подтверждена».
  appointmentConfirmed,

  /// «Вам пришло сообщение».
  doctorMessage,
}

/// Строка списка уведомлений.
///
/// Хранит не готовую фразу, а её части: врача и время приёма. Текст
/// собирается на экране через `AppLocalizations` — иначе при переключении
/// языка уведомления остались бы русскими.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.doctorName,
    required this.createdAt,
    this.appointmentAt,
  });

  final String id;
  final NotificationKind kind;

  /// «Имя Фамилия» — тот, о ком уведомление.
  final String doctorName;

  /// Когда пришло: время в правом верхнем углу строки.
  final DateTime createdAt;

  /// Время приёма. Только у [NotificationKind.appointmentConfirmed] — у
  /// сообщения его нет.
  final DateTime? appointmentAt;

  /// «21.07, 13:44» — как в списке чатов.
  String get timeLabel =>
      '${RuDates.dayMonth(createdAt)}, ${RuDates.hourMinute(createdAt)}';

  /// «13:30, 27 июля» — время приёма в подписи подтверждения.
  String get appointmentLabel => appointmentAt == null
      ? ''
      : '${RuDates.time(appointmentAt!)}, ${RuDates.dayAndMonth(appointmentAt!)}';
}
