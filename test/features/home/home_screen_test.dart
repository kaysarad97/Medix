import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/home/presentation/providers/home_providers.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/home/presentation/screens/home_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Смена локали действительно переводит интерфейс — не только собирается.
///
/// Данные (специальности, записи) не локализуются: это мок-контент с
/// бэкенда, а не строки интерфейса — см. l10n.yaml/lib/l10n.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpHome(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(440, 1299);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          specialtiesProvider.overrideWith((ref) => const []),
          upcomingAppointmentsProvider.overrideWith((ref) => const []),
          // По той же причине: заглушка семьи отдаёт данные через
          // Future.delayed, и таймер переживает тест.
          familyRepositoryProvider.overrideWithValue(FakeFamilyRepository()),
          // Экран смотрит на тариф: семейный доступ входит в Gold.
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('ru — заголовки на русском', (tester) async {
    await pumpHome(tester, const Locale('ru'));

    expect(find.text('Как Ваше здоровье сегодня?'), findsOneWidget);
    expect(find.text('Загрузить анализы'), findsOneWidget);
    expect(find.text('Предстоящие записи'), findsOneWidget);
  });

  testWidgets('«Моя Семья» ведёт в профили близких, а не показывает имена', (
    tester,
  ) async {
    await pumpHome(tester, const Locale('ru'));

    expect(find.text('Моя Семья'), findsOneWidget);
    expect(find.text('Профиль для ребенка'), findsOneWidget);
    expect(find.text('Профиль для старшего поколения'), findsOneWidget);
    expect(find.text('мед-карта и процедуры'), findsNWidgets(2));
    // На главной это вход в чужой профиль: имён быть не должно, в отличие
    // от той же карточки в мед-карте.
    expect(find.text('Имя Фамилия'), findsNothing);
  });

  testWidgets('kk — те же заголовки на казахском', (tester) async {
    await pumpHome(tester, const Locale('kk'));

    expect(find.text('Бүгін денсаулығыңыз қалай?'), findsOneWidget);
    expect(find.text('Талдауларды жүктеу'), findsOneWidget);
    expect(find.text('Алдағы жазбалар'), findsOneWidget);
    expect(find.text('Как Ваше здоровье сегодня?'), findsNothing);
  });

  testWidgets('en — те же заголовки на английском', (tester) async {
    await pumpHome(tester, const Locale('en'));

    expect(find.text("How's your health today?"), findsOneWidget);
    expect(find.text('Upload test results'), findsOneWidget);
    expect(find.text('Upcoming appointments'), findsOneWidget);
  });
}
