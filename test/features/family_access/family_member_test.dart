import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
    await tester.pump();
  }

  group('карточка ребёнка', () {
    final screen = FamilyMemberScreen(
      memberId: 'f1',
      now: DateTime(2026, 8, 6),
    );

    testWidgets('рисует шапку, мед-карту и врачей', (tester) async {
      await pumpScreen(tester, screen);

      expect(find.text('Моя Семья'), findsOneWidget);
      expect(find.text('мужчина'), findsOneWidget);
      expect(find.text('7/10/2020'), findsOneWidget);
      expect(find.text('5 лет'), findsOneWidget);
      expect(find.text('106 см'), findsOneWidget);
      expect(find.text('Родство с Вами'), findsOneWidget);
      expect(find.text('Врачи моего ребёнка'), findsOneWidget);
      expect(find.text('Педиатр'), findsOneWidget);
      expect(find.text('Анализы ребёнка'), findsOneWidget);
    });
  });

  group('карточка старших', () {
    final screen = FamilyMemberScreen(
      memberId: 'f2',
      now: DateTime(2026, 8, 6),
    );

    testWidgets('заголовки завязаны на имя, а не на «ребёнка»', (tester) async {
      await pumpScreen(tester, screen);

      expect(find.text('женщина'), findsOneWidget);
      expect(find.text('68 лет'), findsOneWidget);
      expect(find.text('Врачи для старших'), findsOneWidget);
      expect(find.text('Кардиолог'), findsOneWidget);
      expect(find.text('Анализы Имя Фамилия'), findsOneWidget);
    });
  });

  testWidgets('неизвестный id показывает индикатор загрузки без падения', (
    tester,
  ) async {
    await pumpScreen(tester, const FamilyMemberScreen(memberId: 'nope'));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
