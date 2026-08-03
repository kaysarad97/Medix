@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/medix_wait_view.dart';

import '../../helpers/test_fonts.dart';

/// Эталоны для `design/Загрузка.png` и `design/Подождите....png`.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpView(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: view),
      ),
    );

    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      await precacheImage(
        const AssetImage('assets/images/auth_bg.png'),
        context,
      );
      await precacheImage(
        const AssetImage('assets/images/logo_medix.png'),
        context,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  testWidgets('заставка запуска', (tester) async {
    await pumpView(tester, const MedixWaitView());

    await expectLater(
      find.byType(MedixWaitView),
      matchesGoldenFile('goldens/wait_view_splash.png'),
    );
  });

  testWidgets('ожидание с подписями', (tester) async {
    await pumpView(
      tester,
      const MedixWaitView(
        title: 'подождите...',
        subtitle: 'проверяем данные карты...',
      ),
    );

    await expectLater(
      find.byType(MedixWaitView),
      matchesGoldenFile('goldens/wait_view_message.png'),
    );
  });
}
