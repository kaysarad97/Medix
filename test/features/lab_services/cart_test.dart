import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_services_providers.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_offers_screen.dart';
import 'package:medix/features/lab_services/presentation/widgets/cart_sheet.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_lab_services_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Кладёт в корзину два отдельных анализа и комплекс с составом.
  Future<ProviderContainer> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          labServicesRepositoryProvider.overrideWithValue(
            const FakeLabServicesRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    final cart = container.read(labServicesCartProvider.notifier);
    cart.toggle('s1');
    cart.toggle('s7');
    cart.toggle('b4');
    await tester.pump();

    return container;
  }

  group('Моя Корзина', () {
    testWidgets('показывает позиции, состав комплекса и итог', (tester) async {
      await pump(tester, const CartSheet());

      expect(find.text('Моя Корзина'), findsOneWidget);
      expect(find.text('Аланинаминотрансфераза (АЛТ)'), findsOneWidget);
      expect(find.text('Аспартатаминотрансфераза (АСТ)'), findsOneWidget);
      expect(find.text('Комплекс “Вегетарианский”'), findsOneWidget);
      // Комплекс раскрывается составом — в отличие от отдельных анализов.
      expect(find.text('·  Витамин B12'), findsOneWidget);
      // 1000 + 1000 + 5000.
      expect(find.text('7000 ₸'), findsOneWidget);
    });

    testWidgets('нумерует позиции по порядку каталога', (tester) async {
      await pump(tester, const CartSheet());

      for (final number in ['1', '2', '3']) {
        expect(find.text(number), findsOneWidget);
      }
    });

    test('сумма считается по ценам позиций', () {
      final container = ProviderContainer(
        overrides: [
          labServicesRepositoryProvider.overrideWithValue(
            const FakeLabServicesRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Каталог ещё не загрузился — корзина пуста, и итог нулевой.
      expect(container.read(cartTotalProvider), 0);
    });
  });

  group('Партнерские лаборатории', () {
    testWidgets('показывает свою корзину списком и итогом', (tester) async {
      await pump(tester, const LabOffersScreen());

      expect(find.text('Партнерские лаборатории'), findsOneWidget);
      expect(find.textContaining('Ваша Корзина в'), findsOneWidget);
      // Комплекс раскрыт: сравнивать надо одинаковые наборы анализов.
      expect(find.text('·  Кальций общий'), findsOneWidget);
      expect(find.text('7000 ₸'), findsOneWidget);
    });

    testWidgets('показывает предложения партнёров с ценой и статусом', (
      tester,
    ) async {
      await pump(tester, const LabOffersScreen());

      expect(find.text('Другие предложения'), findsOneWidget);
      expect(find.text('Лаборатория N1'), findsOneWidget);
      expect(find.text('2900 ₸'), findsOneWidget);
      // Две ближние лаборатории в заглушке на одном расстоянии.
      expect(find.text('900м'), findsNWidgets(2));
      // Третий партнёр в заглушке закрыт — статус берётся из данных.
      expect(find.text('Закрыто'), findsOneWidget);
    });
  });
}
