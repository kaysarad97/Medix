import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/auth/presentation/screens/login_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/auth_overrides.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpLogin(WidgetTester tester) async {
    // Макет 440×956 — гоняем тест в тех же размерах, что и дизайн.
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
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
    await tester.pump();
  }

  testWidgets('рисует элементы шага 1 входа: только почта', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Логин'), findsOneWidget);
    expect(find.text('Ваш E-mail:'), findsOneWidget);
    expect(find.text('или авторизоваться через'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
    expect(find.text('или создать профиль'), findsOneWidget);

    // Поле пароля убрано вместе с паролями — на экране ровно одно поле.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Пароль:'), findsNothing);
  });

  testWidgets('кнопка неактивна, пока поле пустое', (tester) async {
    await pumpLogin(tester);

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('кнопка активируется после ввода почты', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField), 'abcedfg@gmail.com');
    await tester.pump();

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('некорректный e-mail показывает ошибку под полем', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.enterText(find.byType(TextField), 'не-почта');
    await tester.pump();

    await tester.tap(find.text('Получить код'));
    await tester.pump();

    expect(find.text('Некорректный e-mail'), findsOneWidget);
  });

  testWidgets('высота кнопки и поля совпадает с макетом', (tester) async {
    await pumpLogin(tester);

    expect(tester.getSize(find.byType(PrimaryButton)).height, 70);

    final fieldBox = tester.getSize(
      find
          .ancestor(
            of: find.byType(TextField).first,
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(fieldBox.height, 66);
  });
}
