import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/constants/app_constants.dart';
import 'package:medix/core/theme/app_spacing.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/auth/presentation/screens/personal_data_screen.dart';
import 'package:medix/features/auth/presentation/screens/register_screen.dart';
import 'package:medix/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:medix/features/auth/presentation/widgets/otp_code_input.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/auth_overrides.dart';
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
        overrides: authOverrides,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Создайте профиль: одно поле почты и неактивная кнопка', (
    tester,
  ) async {
    await pumpScreen(tester, const RegisterScreen());

    expect(find.text('Создайте профиль'), findsOneWidget);
    expect(find.text('Введите Вашу почту'), findsOneWidget);

    // Паролей нет — поле осталось одно.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Придумайте пароль'), findsNothing);

    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNull,
    );
  });

  testWidgets('кнопка активируется после ввода почты', (tester) async {
    await pumpScreen(tester, const RegisterScreen());

    await tester.enterText(find.byType(TextField), 'user@medix.kz');
    await tester.pump();

    expect(
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('некорректная почта показывает ошибку под полем', (tester) async {
    await pumpScreen(tester, const RegisterScreen());

    await tester.enterText(find.byType(TextField), 'не-почта');
    await tester.pump();

    await tester.tap(find.text('Далее'));
    await tester.pump();

    expect(find.text('Некорректный e-mail'), findsOneWidget);
  });

  testWidgets('Ваши данные: ФИО и дата рождения', (tester) async {
    await pumpScreen(tester, const PersonalDataScreen());

    expect(find.text('Ваши данные'), findsOneWidget);
    expect(find.text('ФИО'), findsOneWidget);
    expect(find.text('Дата рождения'), findsOneWidget);

    // ИИН и телефон убраны — бэкенд их не хранит.
    expect(find.text('ИИН'), findsNothing);
    expect(find.text('Номер телефона'), findsNothing);
  });

  testWidgets('Введите код: шесть боксов и обратный отсчёт', (tester) async {
    await pumpScreen(tester, const VerifyCodeScreen());

    expect(find.text('Введите код'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(AppConstants.otpCodeLength));
    expect(
      find.text('выслать письмо с кодом ещё раз через 01:00'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('боксы кода ужимаются под ширину экрана, ввод переносит фокус', (
    tester,
  ) async {
    await pumpScreen(tester, const VerifyCodeScreen());

    final boxes = find.descendant(
      of: find.byType(OtpCodeInput),
      matching: find.byType(SizedBox),
    );
    final first = tester.getRect(boxes.first);

    // Шесть боксов по 70 в ширину 440 не влезают, поэтому ряд ужимается по
    // доступной ширине с сохранением пропорции 70:83 из макета.
    const available = 440 - 2 * AppSpacing.screenH;
    const gaps = OtpCodeInput.gap * (AppConstants.otpCodeLength - 1);
    const expectedWidth = (available - gaps) / AppConstants.otpCodeLength;

    expect(first.width, closeTo(expectedWidth, 0.01));
    expect(
      first.height,
      closeTo(
        expectedWidth * OtpCodeInput.boxHeight / OtpCodeInput.boxWidth,
        0.01,
      ),
    );
    expect(first.width, lessThan(OtpCodeInput.boxWidth));

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump();

    final second = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(second.focusNode?.hasFocus, isTrue);

    await tester.pumpWidget(const SizedBox());
  });
}
