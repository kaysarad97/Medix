import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../domain/entities/app_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  if (useMocks) return const MockNotificationsRepository();

  return RemoteNotificationsRepository(ref.watch(dioClientProvider));
});

/// Экран ленты явно перечитывает данные при каждом открытии.
///
/// `autoDispose` само по себе недостаточно: шапка главной постоянно слушает
/// этот provider ради счётчика и удерживает старый результат. Поэтому
/// `NotificationsScreen.initState` делает `invalidate`, а `autoDispose`
/// освобождает ленту, когда её больше не использует ни экран, ни шапка.
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) => ref.watch(notificationsRepositoryProvider).notifications(),
);

/// Число непрочитанных уведомлений для чипа в шапке главных экранов.
///
/// Пока лента загружается или недоступна, показываем ноль, а не макетное
/// значение: выдуманный счётчик особенно заметен на пустом тестовом аккаунте.
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((notification) => !notification.isRead).length;
});

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
///
/// Тоже `autoDispose` — иначе он пережил бы [notificationsProvider] и держал
/// его в памяти, обнуляя весь смысл перечитывания.
final visibleNotificationsProvider =
    Provider.autoDispose<List<AppNotification>>((ref) {
      final all = ref.watch(notificationsProvider).value ?? const [];
      final filter = ref.watch(notificationsFilterProvider);

      return [
        for (final notification in all)
          if (_matches(notification.kind, filter)) notification,
      ];
    });

bool _matches(NotificationKind kind, NotificationsFilter filter) =>
    switch (filter) {
      NotificationsFilter.schedule => kind == NotificationKind.schedule,
      NotificationsFilter.messages => kind == NotificationKind.message,
    };
