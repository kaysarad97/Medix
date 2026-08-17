import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/notifications/data/repositories/notifications_repository.dart';
import 'package:medix/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:medix/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

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
}
