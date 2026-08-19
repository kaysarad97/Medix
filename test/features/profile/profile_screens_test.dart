import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/icon_chip.dart';
import 'package:medix/core/widgets/user_avatar.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/avatar_picker_screen.dart';
import 'package:medix/features/profile/presentation/screens/contact_screen.dart';
import 'package:medix/features/profile/presentation/screens/medical_card_form_screen.dart';
import 'package:medix/features/profile/presentation/screens/medical_card_screen.dart';
import 'package:medix/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:medix/features/profile/presentation/screens/settings_screen.dart';
import 'package:medix/core/widgets/section_header.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/app_language.dart';
import 'package:medix/shared/models/medix_avatars.dart';

import '../../helpers/fake_family_repository.dart';
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
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
        ],
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

  group('Ваша Мед-Карта', () {
    // Возраст считаем от фиксированной даты, иначе тест сломается в день
    // рождения из заглушки.
    final screen = MedicalCardScreen(now: DateTime(2026, 8, 2));

    testWidgets('рисует шапку с именем, полом и подпиской', (tester) async {
      await pump(tester, screen);

      // Имя и фамилия в шапке — двумя строками, поэтому по отдельности.
      // В карточке «Моя Семья» ниже они склеены в «Имя Фамилия» и сюда
      // не попадают.
      expect(find.text('Имя'), findsOneWidget);
      expect(find.text('Фамилия'), findsOneWidget);
      expect(find.text('мужчина'), findsOneWidget);
      expect(find.text('6/12/1996'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
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

    testWidgets('строка-заголовок нажимается целиком, а не только шеврон', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        Scaffold(
          body: SectionHeader(
            icon: MedixIcon.medicalCard,
            title: 'Мед-карта',
            onTap: () => taps++,
          ),
        ),
      );

      // Жмём по названию, а не по стрелке: `onTap` не был подключён вовсе,
      // строка рисовала шеврон и молчала на любое нажатие.
      await tester.tap(find.text('Мед-карта'));
      expect(taps, 1);
    });

    testWidgets('возраст считается от переданной даты', (tester) async {
      await pump(tester, screen);
      // Родился 6 декабря 1996, на 2 августа 2026 — 29 полных лет.
      expect(find.text('29 лет'), findsOneWidget);
    });

    testWidgets('карточка «Моя Семья» показывает членов семьи и их роли', (
      tester,
    ) async {
      await pump(tester, screen);

      expect(find.text('Моя Семья'), findsOneWidget);
      // Оба мок-члена семьи: заглушка зовёт обоих «Имя Фамилия», роли
      // различаются.
      expect(find.text('Имя Фамилия'), findsNWidgets(2));
      expect(find.text('профиль ребенка'), findsOneWidget);
      expect(find.text('профиль для старшего поколения'), findsOneWidget);
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

  group('Выбор аватарки', () {
    testWidgets('рисует все аватарки из набора', (tester) async {
      await pump(tester, const AvatarPickerScreen());

      expect(find.text('Выбор аватарки'), findsOneWidget);
      expect(find.byType(UserAvatar), findsNWidgets(MedixAvatars.all.length));
    });

    testWidgets('нажатие меняет выбранную', (tester) async {
      await pump(tester, const AvatarPickerScreen());

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AvatarPickerScreen)),
      );
      expect(container.read(avatarSelectionProvider), isNull);

      // Третья по счёту: первая совпадает с запасной, и по ней нельзя
      // отличить выбор от значения по умолчанию.
      await tester.tap(find.byType(UserAvatar).at(2));
      await tester.pump();

      expect(container.read(avatarSelectionProvider), MedixAvatars.all[2]);
      expect(container.read(userAvatarProvider), MedixAvatars.all[2]);
    });
  });

  testWidgets('Настройки профиля: подпись ведёт на выбор аватарки', (
    tester,
  ) async {
    var opened = 0;
    await pump(tester, ProfileSettingsScreen(onChangeAvatar: () => opened++));

    // Раньше роутер строил экран вообще без колбэка, и подпись молчала.
    await tester.tap(find.text('изменить аватара'));
    expect(opened, 1);
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
    // Полей три: поле пароля ушло вместе с паролями — вход по коду из письма.
    expect(fields, hasLength(3));
    expect(fields[0].controller?.text, 'Имя');
    expect(fields[1].controller?.text, 'Фамилия');
    expect(fields[2].controller?.text, 'user@medix.kz');
  });

  group('Форма мед-карты', () {
    testWidgets('рисует поля из макета', (tester) async {
      await pump(tester, const MedicalCardFormScreen());
      await tester.pump();

      expect(find.text('Группа крови:'), findsOneWidget);
      expect(find.text('Резус-фактор:'), findsOneWidget);
      expect(find.text('Хронические заболевания'), findsOneWidget);
      expect(
        find.text('Аллергии (пищевые, лекарственные, прочие)'),
        findsOneWidget,
      );
      expect(find.text('Перенесенные операции'), findsOneWidget);
      expect(find.text('Вредные привычки (курение, алкоголь)'), findsOneWidget);
      for (final group in BloodGroup.values) {
        expect(find.text(group.label), findsOneWidget);
      }
      expect(find.text('Rh+'), findsOneWidget);
      expect(find.text('Rh-'), findsOneWidget);
    });

    testWidgets('сохранённое видно на карточке сразу', (tester) async {
      // Ловушка живого API: карта читается провайдером и кэшируется, а
      // форма её меняет на сервере. Без `invalidate` рост и вес появлялись
      // на «Ваша Мед-Карта» только после перезапуска приложения.
      final router = GoRouter(
        initialLocation: Routes.profile,
        routes: [
          GoRoute(
            path: Routes.profile,
            builder: (context, state) =>
                MedicalCardScreen(now: DateTime(2026, 8, 6)),
          ),
          GoRoute(
            path: Routes.medicalCardForm,
            builder: (context, state) => const MedicalCardFormScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(
              FakeProfileRepository(),
            ),
            familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('176 см'), findsOneWidget);

      await tester.tap(find.byType(SectionHeader).first);
      await tester.pumpAndSettle();

      // Поле роста ищем по подставленному значению, а не по месту в
      // форме: порядок полей меняется чаще, чем содержимое.
      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final height = fields.toList().indexWhere(
        (field) => field.controller?.text == '176',
      );
      await tester.enterText(find.byType(TextField).at(height), '181');
      await tester.ensureVisible(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();

      expect(find.text('181 см'), findsOneWidget);
    });

    testWidgets('подставляет уже заполненное', (tester) async {
      await pump(tester, const MedicalCardFormScreen());
      await tester.pump();

      // Заглушка отдаёт I (O), Rh+, рост 176 и вес 77.
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.any((f) => f.controller?.text == '176'), isTrue);
      expect(fields.any((f) => f.controller?.text == '77'), isTrue);
    });

    testWidgets('выбор группы крови переключается', (tester) async {
      await pump(tester, const MedicalCardFormScreen());
      await tester.pump();

      await tester.tap(find.text('III (B)'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Свяжитесь с нами показывает контакты', (tester) async {
    await pump(tester, const ContactScreen());

    expect(find.text('Номера телефона поддержки'), findsOneWidget);
    expect(find.text('+7 700 000 00 00'), findsNWidgets(2));
    expect(find.text('info.medix.clients@gmail.com'), findsOneWidget);
    expect(find.text('Социальные сети'), findsOneWidget);
  });
}
