import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_chatbot/presentation/providers/chatbot_controller.dart';
import 'package:medix/features/lab_chatbot/presentation/screens/chatbot_screen.dart';
import 'package:medix/core/widgets/chat_bubble.dart';
import 'package:medix/core/widgets/chat_input_bar.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/chat_message.dart';

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
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatbotScreen(),
        ),
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

  testWidgets('прикрепление файла отправляет его и показывает разбор', (
    tester,
  ) async {
    await pumpChatbot(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(ChatInputBar),
        matching: find.byTooltip('Прикрепить файл'),
      ),
    );
    await tester.pump();

    // Имя файла ушло как реплика пользователя, бот «печатает».
    expect(find.text('BloodworkResults.pdf'), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);

    await tester.pump(FakeChatbotRepository.delay);
    await tester.pump();

    expect(find.text('Анализирую Ваши результаты…'), findsOneWidget);
    expect(
      find.text('Ваши результаты доступны для просмотра в Вашей мед-карте'),
      findsOneWidget,
    );
    expect(find.byType(TypingIndicator), findsNothing);
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

    test('вложение добавляет реплику пользователя и два ответа бота', () async {
      final c = container.read(chatbotControllerProvider.notifier);
      await c.attachFile();

      final messages = container.read(chatbotControllerProvider).messages;
      expect(messages, hasLength(3));
      expect(messages[0].author, ChatAuthor.user);
      expect(messages[0].text, ChatbotController.mockAttachmentName);
      expect(messages[1].author, ChatAuthor.bot);
      expect(messages[2].author, ChatAuthor.bot);
      expect(container.read(chatbotControllerProvider).botIsTyping, isFalse);
    });

    test(
      'пока бот отвечает на вложение, повторное вложение игнорируется',
      () async {
        final c = container.read(chatbotControllerProvider.notifier);
        final first = c.attachFile();
        await c.attachFile();
        await first;

        expect(
          container.read(chatbotControllerProvider).messages,
          hasLength(3),
        );
      },
    );
  });
}
