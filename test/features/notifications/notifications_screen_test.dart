import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/notifications/data/repositories/notifications_repository.dart';
import 'package:medix/features/notifications/domain/entities/app_notification.dart';
import 'package:medix/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:medix/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  test('счётчик шапки учитывает только непрочитанные', () {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => [
            AppNotification(
              id: 'unread',
              kind: NotificationKind.schedule,
              title: '',
              body: '',
              createdAt: DateTime(2026),
            ),
            AppNotification(
              id: 'read',
              kind: NotificationKind.message,
              title: '',
              body: '',
              createdAt: DateTime(2026),
              isRead: true,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(unreadNotificationsCountProvider), 1);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    // Заглушка отдаёт данные синхронно и без таймеров; боевая реализация
    // ходит в сеть, и без подмены экран остался бы пустым.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            const MockNotificationsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('показывает заголовок, вкладки и записи', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.text('Расписание'), findsOneWidget);
    expect(find.text('Сообщения от врачей'), findsOneWidget);
    // Открывается на «Расписании»: три подтверждения записи из пяти строк.
    expect(find.text('Ваша запись подтверждена'), findsNWidgets(3));
    expect(find.text('Вам пришло сообщение'), findsNothing);
  });

  testWidgets('нажатие отмечает непрочитанное на сервере', (tester) async {
    MockNotificationsRepository.readIds.clear();
    await pumpScreen(tester);

    await tester.tap(find.text('Ваша запись подтверждена').first);
    await tester.pump();

    expect(MockNotificationsRepository.readIds, ['n1']);
  });

  testWidgets('текст приходит с сервера готовым', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text('Имя Фамилия подтвердил запись в 13:30, 27 июля'),
      findsNWidgets(3),
    );
    expect(find.text('21.07, 13:44'), findsNWidgets(3));
  });

  testWidgets('вторая вкладка оставляет только сообщения', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Сообщения от врачей'));
    await tester.pumpAndSettle();

    expect(find.text('Вам пришло сообщение'), findsNWidgets(2));
    expect(find.text('Ваша запись подтверждена'), findsNothing);
    expect(find.text('Имя Фамилия отправил Вам сообщение'), findsNWidgets(2));
  });

  testWidgets('предложение свободного слота открывает лист ожидания', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NotificationsScreen()),
        GoRoute(
          path: Routes.waitlist,
          builder: (_, _) => const Scaffold(body: Text('waitlist-target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsRepositoryProvider.overrideWithValue(
            const _WaitlistNotificationsRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Освободилось время у врача'));
    await tester.pumpAndSettle();

    expect(find.text('waitlist-target'), findsOneWidget);
  });

  testWidgets('при открытии перечитывает ленту, удерживаемую шапкой', (
    tester,
  ) async {
    final repository = _RefreshingNotificationsRepository();
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final keepAlive = container.listen(notificationsProvider, (_, _) {});
    addTearDown(keepAlive.close);
    await container.read(notificationsProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.loadCount, 2);
    expect(find.text('Новое уведомление'), findsOneWidget);
  });
}

class _WaitlistNotificationsRepository extends MockNotificationsRepository {
  const _WaitlistNotificationsRepository();

  static final AppNotification notification = AppNotification(
    id: 'waitlist',
    kind: NotificationKind.schedule,
    apiKind: 'waitlist_offer',
    title: 'Освободилось время у врача',
    body: 'Забронируйте слот',
    createdAt: DateTime(2026, 8, 25),
  );

  @override
  Future<List<AppNotification>> notifications() async => [notification];

  @override
  Future<AppNotification> setRead(String id, {required bool read}) async =>
      AppNotification(
        id: notification.id,
        kind: notification.kind,
        apiKind: notification.apiKind,
        title: notification.title,
        body: notification.body,
        createdAt: notification.createdAt,
        isRead: read,
      );
}

class _RefreshingNotificationsRepository extends MockNotificationsRepository {
  int loadCount = 0;

  @override
  Future<List<AppNotification>> notifications() async {
    loadCount += 1;
    if (loadCount == 1) return const [];
    return [
      AppNotification(
        id: 'new',
        kind: NotificationKind.schedule,
        title: 'Новое уведомление',
        body: 'Получено после открытия экрана',
        createdAt: DateTime(2026, 8, 25),
      ),
    ];
  }
}
