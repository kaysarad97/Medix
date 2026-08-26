@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/map_search/presentation/providers/map_providers.dart';
import 'package:medix/features/map_search/presentation/screens/map_search_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_places_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталон для `design/Поиск (карта).png`.
///
/// Тайлы выключены: они тянутся по сети, которой у теста нет, и эталон
/// зависел бы от того, что успело докачаться. Сверяется всё остальное —
/// заголовок, вкладки, рамка карты и метки на своих местах.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('map_search соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          placesRepositoryProvider.overrideWithValue(
            const FakePlacesRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MapSearchScreen(showTiles: false),
        ),
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump();

    await expectLater(
      find.byType(MapSearchScreen),
      matchesGoldenFile('goldens/map_search.png'),
    );
  });
}
