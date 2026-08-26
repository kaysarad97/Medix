@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/notifications/data/repositories/notifications_repository.dart';
import 'package:medix/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:medix/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Уведомлений» — сверка с `design/Нотификации.png` (440×956).
void main() {
  setUpAll(loadAppFonts);

  testWidgets('notifications соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

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

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
    await precacheScreenImages(tester);

    await expectLater(
      find.byType(NotificationsScreen),
      matchesGoldenFile('goldens/notifications.png'),
    );
  });
}
