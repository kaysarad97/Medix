import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/auth/presentation/screens/personal_data_screen.dart';
import 'package:medix/features/auth/presentation/screens/register_screen.dart';
import 'package:medix/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:medix/features/auth/presentation/widgets/otp_code_input.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
  }

  testWidgets('Создайте профиль: три поля и неактивная кнопка', (tester) async {
    await pumpScreen(tester, const RegisterScreen());

    expect(find.text('Создайте профиль'), findsOneWidget);
    expect(find.text('Введите Вашу почту'), findsOneWidget);
    expect(find.text('Придумайте пароль'), findsOneWidget);
    expect(find.text('Подтвердите пароль'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));

    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
  });

  testWidgets('кнопка «Далее» стоит в габаритах макета', (tester) async {
    await pumpScreen(tester, const RegisterScreen());

    // Замер по `design/Создайте профиль.png`: x 55…384, y 631…685.
    final rect = tester.getRect(find.byType(PrimaryButton));
    expect(rect.left, 55);
    expect(rect.width, 330);
    expect(rect.top, 631);
    expect(rect.height, 55);
  });

  testWidgets('кнопка активируется после заполнения всех полей', (
    tester,
  ) async {
    await pumpScreen(tester, const RegisterScreen());

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'user@medix.kz');
    await tester.enterText(fields.at(1), 'supersecret');
    await tester.enterText(fields.at(2), 'supersecret');
    await tester.pump();

    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('несовпадающие пароли показывают ошибку под полем', (
    tester,
  ) async {
    await pumpScreen(tester, const RegisterScreen());

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'user@medix.kz');
    await tester.enterText(fields.at(1), 'supersecret');
    await tester.enterText(fields.at(2), 'othersecret');
    await tester.pump();

    await tester.tap(find.text('Далее'));
    await tester.pump();

    expect(find.text('Пароли не совпадают'), findsOneWidget);
  });

  testWidgets('Ваши данные: поля ИИН, ФИО и телефон', (tester) async {
    await pumpScreen(tester, const PersonalDataScreen());

    expect(find.text('Ваши данные'), findsOneWidget);
    expect(find.text('ИИН'), findsOneWidget);
    expect(find.text('ФИО'), findsOneWidget);
    expect(find.text('Номер телефона'), findsOneWidget);
  });

  testWidgets('Введите код: пять боксов и обратный отсчёт', (tester) async {
    await pumpScreen(tester, const VerifyCodeScreen());

    expect(find.text('Введите код'), findsOneWidget);
    expect(find.text('Подтвердите личность'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(5));
    expect(
      find.text('выслать СМС-сообщение еще раз через 00:59'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('боксы кода в габаритах макета, ввод переносит фокус', (
    tester,
  ) async {
    await pumpScreen(tester, const VerifyCodeScreen());

    // Замер по `design/Введите код (ПУСТОЙ).png`: 70×83, зазор 12.
    final boxes = find.descendant(
      of: find.byType(OtpCodeInput),
      matching: find.byType(SizedBox),
    );
    final first = tester.getRect(boxes.first);
    expect(first.width, OtpCodeInput.boxWidth);
    expect(first.height, OtpCodeInput.boxHeight);

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump();

    final second = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(second.focusNode?.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
