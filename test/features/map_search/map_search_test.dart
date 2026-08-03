import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/map_search/data/repositories/places_repository.dart';
import 'package:medix/features/map_search/domain/entities/medical_place.dart';
import 'package:medix/features/map_search/presentation/providers/map_providers.dart';
import 'package:medix/features/map_search/presentation/screens/map_search_screen.dart';

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
        child: const MaterialApp(home: MapSearchScreen(showTiles: false)),
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
}
