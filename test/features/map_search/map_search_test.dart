import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/map_search/data/repositories/places_repository.dart';
import 'package:medix/features/map_search/domain/entities/medical_place.dart';
import 'package:medix/features/map_search/presentation/providers/map_providers.dart';
import 'package:medix/features/map_search/presentation/screens/map_search_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_places_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pump(WidgetTester tester) async {
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
    await tester.pump();
    return ProviderScope.containerOf(
      tester.element(find.byType(MapSearchScreen)),
    );
  }

  testWidgets('рисует заголовок и обе вкладки', (tester) async {
    await pump(tester);

    expect(find.textContaining('Больницы и'), findsOneWidget);
    expect(find.text('Больницы'), findsOneWidget);
    expect(find.text('Лаборатории'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('сначала видны метки обоих типов', (tester) async {
    final container = await pump(tester);

    final visible = container.read(visiblePlacesProvider);
    expect(visible.length, MockPlacesRepository.mockPlaces.length);
    expect(visible.any((p) => p.kind == PlaceKind.hospital), isTrue);
    expect(visible.any((p) => p.kind == PlaceKind.laboratory), isTrue);
  });

  testWidgets('вкладка выключает свой слой', (tester) async {
    final container = await pump(tester);

    await tester.tap(find.text('Лаборатории'));
    await tester.pump();

    final visible = container.read(visiblePlacesProvider);
    expect(visible.every((p) => p.kind == PlaceKind.hospital), isTrue);
    expect(visible, isNotEmpty);
  });

  test('последний включённый слой выключить нельзя', () {
    const both = PlaceFilter();
    final onlyHospitals = both.toggled(PlaceKind.laboratory);
    expect(onlyHospitals.hospitals, isTrue);
    expect(onlyHospitals.laboratories, isFalse);

    // Пустая карта пользователю ничего не сообщает, поэтому щелчок по
    // единственному оставшемуся слою ничего не меняет.
    final stillHospitals = onlyHospitals.toggled(PlaceKind.hospital);
    expect(stillHospitals.hospitals, isTrue);
  });

  test('в заглушке есть и больницы, и лаборатории', () {
    final places = MockPlacesRepository.mockPlaces;
    expect(places.where((p) => p.kind == PlaceKind.hospital), isNotEmpty);
    expect(places.where((p) => p.kind == PlaceKind.laboratory), isNotEmpty);

    // Координаты должны попадать в Алматы, иначе метки улетят за кадр.
    for (final place in places) {
      expect(place.position.latitude, closeTo(43.24, 0.1));
      expect(place.position.longitude, closeTo(76.9, 0.15));
    }
  });

  group('карточка места', () {
    testWidgets('выбор места раскрывает карточку с деталями', (tester) async {
      final container = await pump(tester);
      final lab = MockPlacesRepository.mockPlaces.firstWhere(
        (p) => p.id == 'l1',
      );

      container.read(selectedPlaceProvider.notifier).select(lab);
      await tester.pump();

      expect(find.text('Олимп'), findsOneWidget);
      expect(find.text('Открыто'), findsOneWidget);
      expect(find.text('900 м'), findsOneWidget);
      expect(find.text('Показать все филиалы (19)'), findsOneWidget);
      expect(find.text('Сдать анализы в КДЛ «Олимп»'), findsOneWidget);
    });

    testWidgets('у больницы нет кнопки «Сдать анализы»', (tester) async {
      final container = await pump(tester);
      final hospital = MockPlacesRepository.mockPlaces.firstWhere(
        (p) => p.id == 'h1',
      );

      container.read(selectedPlaceProvider.notifier).select(hospital);
      await tester.pump();

      expect(find.textContaining('Сдать анализы'), findsNothing);
      // У h1 branchesCount = 1 — своих филиалов нет, строки тоже нет.
      expect(find.textContaining('Показать все филиалы'), findsNothing);
    });

    testWidgets('кнопка «назад» при выбранном месте снимает выбор', (
      tester,
    ) async {
      final container = await pump(tester);
      final lab = MockPlacesRepository.mockPlaces.first;

      container.read(selectedPlaceProvider.notifier).select(lab);
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(container.read(selectedPlaceProvider), isNull);
      expect(find.text(lab.category), findsNothing);
    });

    testWidgets('«Показать все филиалы» показывает снек-бар', (tester) async {
      final container = await pump(tester);
      final lab = MockPlacesRepository.mockPlaces.firstWhere(
        (p) => p.id == 'l1',
      );

      container.read(selectedPlaceProvider.notifier).select(lab);
      await tester.pump();

      await tester.tap(find.text('Показать все филиалы (19)'));
      await tester.pump();

      expect(find.text('Список филиалов ещё не готов'), findsOneWidget);
    });
  });
}
