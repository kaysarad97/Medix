@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/contact_screen.dart';
import 'package:medix/features/profile/presentation/screens/medical_card_screen.dart';
import 'package:medix/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:medix/features/profile/presentation/screens/settings_screen.dart';

import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны экранов профиля для сверки с `design/Профиль.png`,
/// `design/Настройки Клиента.png`, `design/Настройки Профиля.png`
/// и `design/Свяжитесь с нами.png`.
///
/// РАСХОЖДЕНИЯ С МАКЕТОМ, ОСОЗНАННЫЕ:
///  • имя в шапке прямое, а в макете курсив — в Golos Text курсивного
///    начертания нет (см. ProfileHeader);
///  • колонки «пол» и «дата рождения» делят ширину поровну вместо
///    фиксированных 140 из макета: иначе строка не помещается уже на 440;
///  • иконки шестерёнки, папки, роста, веса, возраста, процедур, анализов,
///    ромба Gold и соцсетей — пустые места, экспорт ещё не приехал
///    (см. MedixIcons.pending).
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
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

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await precacheImage(
        const AssetImage('assets/images/auth_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('medical_card соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      // Возраст от фиксированной даты: иначе эталон протухнет в день
      // рождения из заглушки.
      MedicalCardScreen(now: DateTime(2026, 8, 2)),
      const Size(440, 1511),
    );

    await expectLater(
      find.byType(MedicalCardScreen),
      matchesGoldenFile('goldens/medical_card.png'),
    );
  });

  testWidgets('settings соответствует эталону', (tester) async {
    await pumpScreen(tester, const SettingsScreen(), const Size(440, 956));

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings.png'),
    );
  });

  testWidgets('profile_settings соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      const ProfileSettingsScreen(),
      const Size(440, 956),
    );

    await expectLater(
      find.byType(ProfileSettingsScreen),
      matchesGoldenFile('goldens/profile_settings.png'),
    );
  });

  testWidgets('contacts соответствует эталону', (tester) async {
    await pumpScreen(tester, const ContactScreen(), const Size(440, 956));

    await expectLater(
      find.byType(ContactScreen),
      matchesGoldenFile('goldens/contacts.png'),
    );
  });
}
