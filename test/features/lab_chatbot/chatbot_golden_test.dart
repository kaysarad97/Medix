@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_chatbot/data/repositories/chatbot_repository.dart';
import 'package:medix/features/lab_chatbot/presentation/providers/chatbot_controller.dart';
import 'package:medix/features/lab_chatbot/presentation/screens/chatbot_screen.dart';

import '../../helpers/fake_chatbot_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны для `design/Чат-бот Старт.png` и `design/Чат-бот.png`.
void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpChatbot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        chatbotRepositoryProvider.overrideWithValue(
          const FakeChatbotRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const ChatbotScreen()),
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
    return container;
  }

  testWidgets('старт с частыми вопросами', (tester) async {
    await pumpChatbot(tester);

    await expectLater(
      find.byType(ChatbotScreen),
      matchesGoldenFile('goldens/chatbot_start.png'),
    );
  });

  testWidgets('переписка', (tester) async {
    final container = await pumpChatbot(tester);

    // Без await: ответ заглушки приходит через Future.delayed, а поддельные
    // часы теста двигает только pump. Дождаться его прямо здесь нельзя —
    // тест повиснет.
    unawaited(
      container
          .read(chatbotControllerProvider.notifier)
          .send('Где дешевле сдать анализы?'),
    );
    await tester.pump();
    await tester.pump(FakeChatbotRepository.delay);
    await tester.pump();

    await expectLater(
      find.byType(ChatbotScreen),
      matchesGoldenFile('goldens/chatbot_conversation.png'),
    );
  });

  testWidgets('загрузка анализов', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    // Настоящая заглушка бота, а не Fake из остальных проверок: нужен
    // текст, буквально совпадающий с `design/Загрузка анализов.png`.
    final container = ProviderContainer(
      overrides: [
        chatbotRepositoryProvider.overrideWithValue(
          const MockChatbotRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: const ChatbotScreen()),
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

    final controller = container.read(chatbotControllerProvider.notifier);

    unawaited(controller.send('Хочу загрузить анализы'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();

    unawaited(controller.attachFile());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pump();

    await expectLater(
      find.byType(ChatbotScreen),
      matchesGoldenFile('goldens/chatbot_upload_analyses.png'),
    );
  });
}
