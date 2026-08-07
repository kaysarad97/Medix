import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/auth/presentation/screens/login_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

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

  testWidgets('рисует все элементы макета Логин Старт', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Логин'), findsOneWidget);
    expect(find.text('Ваш E-mail или ИИН:'), findsOneWidget);
    expect(find.text('Пароль:'), findsOneWidget);
    expect(find.text('или авторизоваться через'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
    expect(find.text('или создать профиль'), findsOneWidget);
  });

  testWidgets('кнопка «Войти» неактивна, пока поля пустые', (tester) async {
    await pumpLogin(tester);

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('кнопка активируется после заполнения обоих полей', (
    tester,
  ) async {
    await pumpLogin(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'abcedfg@gmail.com');
    await tester.enterText(fields.at(1), 'supersecret');
    await tester.pump();

    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('некорректный e-mail показывает ошибку под полем', (
    tester,
  ) async {
    await pumpLogin(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'не-почта');
    await tester.enterText(fields.at(1), 'supersecret');
    await tester.pump();

    await tester.tap(find.text('Войти'));
    await tester.pump();

    expect(find.text('Некорректный e-mail'), findsOneWidget);
  });

  testWidgets('высота кнопки и полей совпадает с макетом', (tester) async {
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
