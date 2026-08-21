import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/chat_bubble.dart';
import 'package:medix/core/widgets/chat_input_bar.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_chatbot_controller.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_chatbot_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/chat_message.dart';

import '../../helpers/fake_doctor_chatbot_repository.dart';
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
          doctorChatbotRepositoryProvider.overrideWithValue(
            const FakeDoctorChatbotRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorChatbotScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('пустая переписка показывает частые вопросы врача', (
    tester,
  ) async {
    await pumpChatbot(tester);

    expect(find.text('Medi-bot'), findsOneWidget);
    expect(find.text('Часто задаваемые вопросы:'), findsOneWidget);
    expect(find.text('Высчитать дозу для пациента'), findsOneWidget);
    expect(find.text('Препараты и их совместимость'), findsOneWidget);
    expect(
      find.text('Оформить направление и список анализов для пациента'),
      findsOneWidget,
    );
    expect(find.byType(ChatBubble), findsNothing);
  });

  testWidgets('нажатие на вопрос отправляет его и показывает ответ', (
    tester,
  ) async {
    await pumpChatbot(tester);

    await tester.tap(find.text('Высчитать дозу для пациента'));
    await tester.pump();

    expect(find.byType(ChatBubble), findsOneWidget);
    expect(find.byType(TypingIndicator), findsOneWidget);
    expect(find.text('Часто задаваемые вопросы:'), findsNothing);

    await tester.pump(FakeDoctorChatbotRepository.delay);
    await tester.pump();

    expect(find.byType(ChatBubble), findsNWidgets(2));
    expect(find.byType(TypingIndicator), findsNothing);
  });

  testWidgets('пока бот печатает, строка ввода заблокирована', (tester) async {
    await pumpChatbot(tester);

    await tester.tap(find.text('Препараты и их совместимость'));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byType(ChatInputBar),
        matching: find.byType(TextField),
      ),
    );
    expect(field.enabled, isFalse);

    await tester.pump(FakeDoctorChatbotRepository.delay);
    await tester.pump();
  });

  group('контроллер', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          doctorChatbotRepositoryProvider.overrideWithValue(
            const FakeDoctorChatbotRepository(),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('пустая строка не отправляется', () async {
      final c = container.read(doctorChatbotControllerProvider.notifier);
      await c.send('   ');

      expect(container.read(doctorChatbotControllerProvider).messages, isEmpty);
    });

    test('реплики идут по порядку: сначала врач, потом бот', () async {
      final c = container.read(doctorChatbotControllerProvider.notifier);
      await c.send('Какая доза?');

      final messages = container.read(doctorChatbotControllerProvider).messages;
      expect(messages, hasLength(2));
      expect(messages.first.author, ChatAuthor.user);
      expect(messages.last.author, ChatAuthor.bot);
      expect(
        container.read(doctorChatbotControllerProvider).botIsTyping,
        isFalse,
      );
    });

    test('пока бот отвечает, вторая отправка игнорируется', () async {
      final c = container.read(doctorChatbotControllerProvider.notifier);
      final first = c.send('раз');
      await c.send('два');
      await first;

      expect(
        container.read(doctorChatbotControllerProvider).messages,
        hasLength(2),
      );
    });
  });
}
