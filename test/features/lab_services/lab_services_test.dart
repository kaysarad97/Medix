import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_services_providers.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_services_screen.dart';

import '../../helpers/fake_lab_services_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        labServicesRepositoryProvider.overrideWithValue(
          const FakeLabServicesRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const LabServicesScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return container;
  }

  group('перечень услуг', () {
    testWidgets('показывает каталог, сгруппированный по буквам', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Перечень услуг'), findsOneWidget);
      expect(find.text('А'), findsOneWidget);
      expect(find.text('Б'), findsOneWidget);
      expect(find.text('Аланинаминотрансфераза (АЛТ)'), findsOneWidget);
      // Комплексы не входят во вкладку «отдельные анализы».
      expect(find.text('Общий анализ крови (комплекс)'), findsNothing);
    });

    testWidgets('вкладка «комплексы анализов» показывает только комплексы', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('комплексы анализов'));
      await tester.pump();

      expect(find.text('Общий анализ крови (комплекс)'), findsOneWidget);
      expect(find.text('Аланинаминотрансфераза (АЛТ)'), findsNothing);
    });

    testWidgets('поиск отфильтровывает лишние строки', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'Билирубин');
      await tester.pump();

      expect(find.text('Билирубин общий'), findsOneWidget);
      expect(find.text('Аланинаминотрансфераза (АЛТ)'), findsNothing);
    });

    testWidgets('нажатие на строку добавляет услугу в корзину', (tester) async {
      final container = await pumpScreen(tester);

      expect(container.read(labServicesCartProvider), isEmpty);

      await tester.tap(find.text('Аланинаминотрансфераза (АЛТ)'));
      await tester.pump();

      expect(container.read(labServicesCartProvider), {'s1'});
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Аланинаминотрансфераза (АЛТ)'));
      await tester.pump();

      expect(container.read(labServicesCartProvider), isEmpty);
    });
  });
}
