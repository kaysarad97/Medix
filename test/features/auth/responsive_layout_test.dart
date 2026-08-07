import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/app_text_field.dart';
import 'package:medix/features/auth/presentation/screens/register_screen.dart';
import 'package:medix/features/auth/presentation/screens/verify_code_screen.dart';
import 'package:medix/features/auth/presentation/widgets/otp_code_input.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

/// Проверки на реальных размерах устройств, а не только на размере макета.
///
/// Макеты нарисованы под 440×956 (iPhone 16 Pro Max). Оба бага ниже
/// проявились только на телефоне: Galaxy S23 FE — 393×830 логических точек.
void main() {
  setUpAll(loadAppFonts);

  /// Ширина макета и ширина самого узкого целевого устройства.
  const sizes = <String, Size>{
    'макет 440×956': Size(440, 956),
    'Galaxy S23 FE 393×830': Size(393, 830),
    'узкий 360×740': Size(360, 740),
  };

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
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

  group('боксы кода помещаются на экран', () {
    for (final entry in sizes.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpScreen(tester, const VerifyCodeScreen(), entry.value);

        expect(tester.takeException(), isNull);

        // Крайние боксы не должны выходить за края экрана.
        final first = tester.getRect(find.byKey(OtpCodeInput.boxKey(0)));
        final last = tester.getRect(find.byKey(OtpCodeInput.boxKey(4)));
        expect(first.left, greaterThanOrEqualTo(0));
        expect(last.right, lessThanOrEqualTo(entry.value.width));

        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('на ширине макета боксы остаются 70×83', (tester) async {
      await pumpScreen(tester, const VerifyCodeScreen(), const Size(440, 956));

      final box = tester.getRect(find.byKey(OtpCodeInput.boxKey(0))).size;
      expect(box.width, OtpCodeInput.boxWidth);
      expect(box.height, OtpCodeInput.boxHeight);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('цифра в боксе кода центрирована', () {
    for (final entry in sizes.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpScreen(tester, const VerifyCodeScreen(), entry.value);

        await tester.enterText(
          find.descendant(
            of: find.byKey(OtpCodeInput.boxKey(0)),
            matching: find.byType(TextField),
          ),
          '7',
        );
        await tester.pump();

        for (var i = 0; i < 5; i++) {
          final boxFinder = find.byKey(OtpCodeInput.boxKey(i));
          final box = tester.getRect(boxFinder);
          final editable = tester.getRect(
            find.descendant(of: boxFinder, matching: find.byType(EditableText)),
          );
          expect(
            (editable.center.dy - box.center.dy).abs(),
            lessThanOrEqualTo(2),
            reason: 'бокс $i: цифра смещена относительно центра',
          );
          expect(
            (editable.center.dx - box.center.dx).abs(),
            lessThanOrEqualTo(2),
            reason: 'бокс $i: цифра смещена по горизонтали',
          );
        }

        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('текст в поле центрирован по вертикали', () {
    for (final entry in sizes.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpScreen(tester, const RegisterScreen(), entry.value);

        final fields = find.byType(AppTextField);
        expect(fields, findsNWidgets(3));

        // На этом экране у полей нет подписей, поэтому рамка AppTextField
        // совпадает с самим полем. Второе и третье поле — с иконкой «глаз»:
        // именно она раньше уводила текст на 12 выше центра.
        for (var i = 0; i < 3; i++) {
          final field = tester.getRect(fields.at(i));
          final editable = tester.getRect(
            find.descendant(
              of: fields.at(i),
              matching: find.byType(EditableText),
            ),
          );
          expect(
            (editable.center.dy - field.center.dy).abs(),
            lessThanOrEqualTo(2),
            reason: 'поле $i: текст смещён относительно центра',
          );
        }
      });
    }
  });
}
