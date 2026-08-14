import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notifications_repository.dart';
import '../../domain/entities/app_notification.dart';

/// Провайдера с выбором `useMocks` здесь нет намеренно: боевой реализации не
/// существует, на сервере модуль уведомлений — заготовка. См.
/// [MockNotificationsRepository].
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => const MockNotificationsRepository(),
);

final notificationsProvider = FutureProvider<List<AppNotification>>(
  (ref) => ref.watch(notificationsRepositoryProvider).notifications(),
);

/// Вкладки над списком.
enum NotificationsFilter {
  /// «Расписание» — всё про записи к врачу.
  schedule,

  /// «Сообщения от врачей».
  messages,
}

final notificationsFilterProvider =
    NotifierProvider<NotificationsFilterNotifier, NotificationsFilter>(
      NotificationsFilterNotifier.new,
    );

class NotificationsFilterNotifier extends Notifier<NotificationsFilter> {
  @override
  NotificationsFilter build() => NotificationsFilter.schedule;

  void select(NotificationsFilter filter) => state = filter;
}

/// Список под выбранной вкладкой.
final visibleNotificationsProvider = Provider<List<AppNotification>>((ref) {
  final all = ref.watch(notificationsProvider).value ?? const [];
  final filter = ref.watch(notificationsFilterProvider);

  return [
    for (final notification in all)
      if (_matches(notification.kind, filter)) notification,
  ];
});

bool _matches(NotificationKind kind, NotificationsFilter filter) =>
    switch (filter) {
      NotificationsFilter.schedule =>
        kind == NotificationKind.appointmentConfirmed,
      NotificationsFilter.messages => kind == NotificationKind.doctorMessage,
    };
