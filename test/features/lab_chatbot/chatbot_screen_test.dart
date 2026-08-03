import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_chatbot/domain/entities/chat_message.dart';
import 'package:medix/features/lab_chatbot/presentation/providers/chatbot_controller.dart';
import 'package:medix/features/lab_chatbot/presentation/screens/chatbot_screen.dart';
import 'package:medix/features/lab_chatbot/presentation/widgets/chat_bubble.dart';
import 'package:medix/features/lab_chatbot/presentation/widgets/chat_input_bar.dart';

import '../../helpers/fake_chatbot_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpChatbot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatbotRepositoryProvider.overrideWithValue(
            const FakeChatbotRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ChatbotScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('пустая переписка показывает частые вопросы', (tester) async {
    await pumpChatbot(tester);

    expect(find.text('Medi-bot'), findsOneWidget);
    expect(find.text('Часто задаваемые вопросы:'), findsOneWidget);
    expect(find.text('Хочу загрузить анализы'), findsOneWidget);
    expect(find.text('Хочу загрузить направление'), findsOneWidget);
    expect(find.text('Где дешевле сдать анализы?'), findsOneWidget);
    expect(find.byType(ChatBubble), findsNothing);
  });

  testWidgets('дисклеймер про диагнозы виден на старте', (tester) async {
    await pumpChatbot(tester);

    // Требование ТЗ, в макетах его нет — см. комментарий в ChatbotScreen.
    expect(find.textContaining('не ставит диагнозы'), findsOneWidget);
  });

  testWidgets('нажатие на вопрос отправляет его и показывает ответ', (
    tester,
  ) async {
    await pumpChatbot(tester);

    await tester.tap(find.text('Где дешевле сдать анализы?'));
    await tester.pump();

    // Реплика пользователя ушла, бот «печатает».
    expect(find.byType(ChatBubble), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Часто задаваемые вопросы:'), findsNothing);

    await tester.pump(FakeChatbotRepository.delay);
    await tester.pump();

    expect(find.byType(ChatBubble), findsNWidgets(2));
    expect(find.byType(TypingIndicator), findsNothing);
  });

  testWidgets('пока бот печатает, строка ввода заблокирована', (tester) async {
    await pumpChatbot(tester);

    await tester.tap(find.text('Хочу загрузить анализы'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byType(ChatInputBar),
        matching: find.byType(TextField),
      ),
    );
    expect(field.enabled, isFalse);

    await tester.pump(FakeChatbotRepository.delay);
    await tester.pump();
  });

  group('контроллер', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          chatbotRepositoryProvider.overrideWithValue(
            const FakeChatbotRepository(),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('пустая строка не отправляется', () async {
      final c = container.read(chatbotControllerProvider.notifier);
      await c.send('   ');

      expect(container.read(chatbotControllerProvider).messages, isEmpty);
    });

    test('реплики идут по порядку: сначала пользователь, потом бот', () async {
      final c = container.read(chatbotControllerProvider.notifier);
      await c.send('Где дешевле?');

      final messages = container.read(chatbotControllerProvider).messages;
      expect(messages, hasLength(2));
      expect(messages.first.author, ChatAuthor.user);
      expect(messages.last.author, ChatAuthor.bot);
      expect(container.read(chatbotControllerProvider).botIsTyping, isFalse);
    });

    test('пока бот отвечает, вторая отправка игнорируется', () async {
      final c = container.read(chatbotControllerProvider.notifier);
      final first = c.send('раз');
      await c.send('два');
      await first;

      // Должна пройти только первая пара реплик.
      expect(container.read(chatbotControllerProvider).messages, hasLength(2));
    });
  });
}
