import '../../domain/entities/app_notification.dart';

/// Откуда берётся список уведомлений.
abstract interface class NotificationsRepository {
  Future<List<AppNotification>> notifications();
}

/// Заглушка на время, пока уведомлений нет на сервере.
///
/// БОЕВОЙ РЕАЛИЗАЦИИ НЕТ, И ВЗЯТЬСЯ ЕЙ ПОКА НЕОТКУДА. `GET /notifications/`
/// на бэкенде отвечает `{"module": "notifications", "status": "scaffolded"}`
/// — это заготовка модуля, а не список: ни текста, ни времени, ни врача она
/// не отдаёт (`app/routers/notifications.py`). Как только эндпоинт появится,
/// рядом встанет `RemoteNotificationsRepository`, а провайдер начнёт
/// переключаться по `useMocks`, как в семье и профиле.
///
/// Содержимое повторяет `design/Нотификации.png`: пять строк, из них две о
/// сообщениях. Даты заданы жёстко, а не «сегодня минус час» — иначе подписи
/// в тестах менялись бы каждый день.
class MockNotificationsRepository implements NotificationsRepository {
  const MockNotificationsRepository();

  @override
  Future<List<AppNotification>> notifications() async => mockNotifications;

  static final List<AppNotification> mockNotifications = [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.appointmentConfirmed,
      doctorName: 'Имя Фамилия',
      createdAt: DateTime(2026, 7, 21, 13, 44),
      appointmentAt: DateTime(2026, 7, 27, 13, 30),
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.doctorMessage,
      doctorName: 'Имя Фамилия',
      createdAt: DateTime(2026, 7, 21, 13, 44),
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.appointmentConfirmed,
      doctorName: 'Имя Фамилия',
      createdAt: DateTime(2026, 7, 21, 13, 44),
      appointmentAt: DateTime(2026, 7, 27, 13, 30),
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.appointmentConfirmed,
      doctorName: 'Имя Фамилия',
      createdAt: DateTime(2026, 7, 21, 13, 44),
      appointmentAt: DateTime(2026, 7, 27, 13, 30),
    ),
    AppNotification(
      id: 'n5',
      kind: NotificationKind.doctorMessage,
      doctorName: 'Имя Фамилия',
      createdAt: DateTime(2026, 7, 21, 13, 44),
    ),
  ];
}
