import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/notifications/data/repositories/notifications_repository.dart';
import 'package:medix/features/notifications/domain/entities/app_notification.dart';

import '../../helpers/canned_dio.dart';

/// Разбор ленты уведомлений бэкенда `smart-med`.
///
/// Тело ответа снято со схемы сервера (`NotificationOut`): текст приходит
/// готовым, а `kind` — свободной строкой, а не перечислением.
void main() {
  CannedResponse feed(List<Map<String, Object?>> items) =>
      (statusCode: 200, body: items);

  Map<String, Object?> item({
    required String id,
    required String kind,
    String title = 'Заголовок',
    String body = 'Текст',
    String? readAt,
  }) => {
    'id': id,
    'kind': kind,
    'title': title,
    'body': body,
    'payload': <String, Object?>{},
    'read_at': readAt,
    'created_at': '2026-07-21T13:44:00',
  };

  test('текст берётся с сервера как есть', () async {
    final (:dio, :adapter) = cannedDio({
      '/notifications': feed([
        item(
          id: 'n1',
          kind: 'appointment_reminder',
          title: 'Напоминание о приёме',
          body: 'Напоминание о приёме 27.07 в 13:30',
        ),
      ]),
    });

    final notifications = await RemoteNotificationsRepository(
      dio,
    ).notifications();

    expect(notifications.single.title, 'Напоминание о приёме');
    expect(notifications.single.body, 'Напоминание о приёме 27.07 в 13:30');
    expect(notifications.single.timeLabel, '21.07, 13:44');
    expect(adapter.requests.single.path, '/notifications');
  });

  test('вид раскладывается по двум вкладкам макета', () async {
    final (:dio, adapter: _) = cannedDio({
      '/notifications': feed([
        item(id: 'n1', kind: 'appointment_reminder'),
        item(id: 'n2', kind: 'new_message'),
        // Незнакомый вид уходит в «Расписание»: третьей вкладки в макете
        // нет, и терять уведомление нельзя.
        item(id: 'n3', kind: 'general'),
      ]),
    });

    final kinds = (await RemoteNotificationsRepository(
      dio,
    ).notifications()).map((n) => n.kind).toList();

    expect(kinds, [
      NotificationKind.schedule,
      NotificationKind.message,
      NotificationKind.schedule,
    ]);
  });

  test('прочитанность видна по отметке времени', () async {
    final (:dio, adapter: _) = cannedDio({
      '/notifications': feed([
        item(id: 'n1', kind: 'general'),
        item(id: 'n2', kind: 'general', readAt: '2026-07-21T14:00:00'),
      ]),
    });

    final notifications = await RemoteNotificationsRepository(
      dio,
    ).notifications();

    expect(notifications.first.isRead, isFalse);
    expect(notifications.last.isRead, isTrue);
  });
}
