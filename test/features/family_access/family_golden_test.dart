@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/family_access/presentation/providers/family_providers.dart';
import 'package:medix/features/family_access/presentation/screens/family_list_screen.dart';
import 'package:medix/features/family_access/presentation/screens/family_member_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_family_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны семейного доступа — сверка с `design/Профили семьи.png` (440×956)
/// и `design/Моя Семья Ребенок.png` (440×1673, страница прокручиваемая).
///
/// Карточка члена семьи снимается на 1200 точках: ниже в макете только
/// пустое место под таб-баром.
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

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
    await precacheScreenImages(tester);
  }

  testWidgets('family_list соответствует эталону', (tester) async {
    await pumpScreen(tester, const FamilyListScreen(), const Size(440, 956));

    await expectLater(
      find.byType(FamilyListScreen),
      matchesGoldenFile('goldens/family_list.png'),
    );
  });

  testWidgets('family_member соответствует эталону', (tester) async {
    await pumpScreen(
      tester,
      const FamilyMemberScreen(memberId: 'f1'),
      const Size(440, 1200),
    );

    await expectLater(
      find.byType(FamilyMemberScreen),
      matchesGoldenFile('goldens/family_member.png'),
    );
  });
}
