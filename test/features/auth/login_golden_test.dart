@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/auth/presentation/screens/login_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/auth_overrides.dart';
import '../../helpers/test_fonts.dart';

/// Эталонный рендер логина для сверки с `design/Логин Старт.png`.
///
/// Размер и devicePixelRatio выставлены так, чтобы результат был 1:1 с
/// макетом (440×956). Поля заполнены теми же значениями, что и в макете.
/// Обновление: `flutter test --update-goldens`.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('login_screen соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    // Безопасные зоны iPhone 16 Pro Max — их же закладывали в вёрстку.
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: authOverrides,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'abcedfg@gmail.com');
    await tester.enterText(fields.at(1), 'password');

    // Фоновая картинка и SVG декодируются асинхронно — без runAsync
    // в golden попадёт пустой прямоугольник.
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LoginScreen));
      await precacheImage(
        const AssetImage('assets/images/auth_bg.png'),
        context,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(LoginScreen),
      matchesGoldenFile('goldens/login_screen.png'),
    );
  });
}
