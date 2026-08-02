import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/contact_screen.dart';
import 'package:medix/features/profile/presentation/screens/medical_card_screen.dart';
import 'package:medix/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:medix/features/profile/presentation/screens/settings_screen.dart';
import 'package:medix/shared/models/app_language.dart';

import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            const FakeProfileRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
  }

  group('Ваша Мед-Карта', () {
    // Возраст считаем от фиксированной даты, иначе тест сломается в день
    // рождения из заглушки.
    final screen = MedicalCardScreen(now: DateTime(2026, 8, 2));

    testWidgets('рисует шапку с именем, полом и подпиской', (tester) async {
      await pump(tester, screen);

      expect(find.text('Имя'), findsOneWidget);
      expect(find.text('Фамилия'), findsOneWidget);
      expect(find.text('мужчина'), findsOneWidget);
      expect(find.text('6/12/1996'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
    });

    testWidgets('рисует карточки мед-карты, врачей и анализов', (tester) async {
      await pump(tester, screen);

      expect(find.text('Мед-карта'), findsOneWidget);
      expect(find.text('176 см'), findsOneWidget);
      expect(find.text('77 кг'), findsOneWidget);
      expect(find.text('Мои Врачи'), findsOneWidget);
      expect(find.text('Офтальмолог'), findsOneWidget);
      expect(find.text('Предыдущие процедуры'), findsOneWidget);
      expect(find.text('Ваши анализы'), findsOneWidget);
    });

    testWidgets('возраст считается от переданной даты', (tester) async {
      await pump(tester, screen);
      // Родился 6 декабря 1996, на 2 августа 2026 — 29 полных лет.
      expect(find.text('29 лет'), findsOneWidget);
    });
  });

  group('Настройки', () {
    testWidgets('рисует строки из макета', (tester) async {
      await pump(tester, const SettingsScreen());

      expect(find.text('Настройки'), findsOneWidget);
      expect(find.text('Настройки профиля'), findsOneWidget);
      expect(find.text('Уведомления'), findsOneWidget);
      expect(find.text('Язык приложения'), findsOneWidget);
      expect(find.text('Банковские данные'), findsOneWidget);
      expect(find.text('Свяжитесь с нами'), findsOneWidget);
      for (final language in AppLanguage.values) {
        expect(find.text(language.label), findsOneWidget);
      }
    });

    testWidgets('переключатель уведомлений меняет состояние', (tester) async {
      await pump(tester, const SettingsScreen());

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(appSettingsProvider).notificationsEnabled, isTrue);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(container.read(appSettingsProvider).notificationsEnabled, isFalse);
    });

    testWidgets('выбор языка запоминается', (tester) async {
      await pump(tester, const SettingsScreen());

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(appSettingsProvider).language, AppLanguage.ru);

      await tester.tap(find.text('Қазақша'));
      await tester.pump();

      expect(container.read(appSettingsProvider).language, AppLanguage.kk);
    });
  });

  testWidgets('Настройки профиля подставляют данные аккаунта', (tester) async {
    await pump(tester, const ProfileSettingsScreen());
    await tester.pump();

    expect(find.text('изменить аватара'), findsOneWidget);

    // Поля не пустые: форма открывается поверх заполненного аккаунта.
    // Проверяем содержимое контроллеров, а не текст на экране: «Имя» тут
    // и значение поля, и подсказка соседнего.
    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(4));
    expect(fields[0].controller?.text, 'Имя');
    expect(fields[1].controller?.text, 'Фамилия');
    expect(fields[2].controller?.text, 'user@medix.kz');
    expect(fields[3].controller?.text, isEmpty);
  });

  testWidgets('Свяжитесь с нами показывает контакты', (tester) async {
    await pump(tester, const ContactScreen());

    expect(find.text('Номера телефона поддержки'), findsOneWidget);
    expect(find.text('+7 700 000 00 00'), findsNWidgets(2));
    expect(find.text('info.medix.clients@gmail.com'), findsOneWidget);
    expect(find.text('Социальные сети'), findsOneWidget);
  });
}
