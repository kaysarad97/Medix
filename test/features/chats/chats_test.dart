import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/chat_bubble.dart';
import 'package:medix/features/chats/domain/entities/chat_thread.dart';
import 'package:medix/features/chats/presentation/providers/chats_providers.dart';
import 'package:medix/features/chats/presentation/screens/chats_list_screen.dart';
import 'package:medix/features/chats/presentation/screens/doctor_chat_screen.dart';

import '../../helpers/fake_chats_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    Widget screen,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        chatsRepositoryProvider.overrideWithValue(const FakeChatsRepository()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
    await tester.pump(FakeChatsRepository.delay);
    await tester.pump();
    return container;
  }

  group('список чатов', () {
    testWidgets('показывает все переписки', (tester) async {
      await pumpScreen(tester, const ChatsListScreen());

      expect(find.text('Все чаты'), findsOneWidget);
      // Все четыре переписки помещаются на экран без прокрутки.
      expect(find.text('Имя Фамилия'), findsNWidgets(4));
      expect(find.textContaining('Вы: Здравствуйте'), findsOneWidget);
    });

    testWidgets('поиск отсеивает лишние строки', (tester) async {
      final container = await pumpScreen(tester, const ChatsListScreen());

      container.read(chatSearchQueryProvider.notifier).update('подтверждена');
      await tester.pump();

      expect(find.textContaining('Запись подтверждена'), findsOneWidget);
      expect(find.textContaining('Вы: Здравствуйте'), findsNothing);
    });
  });

  group('переписка с врачом', () {
    testWidgets('показывает историю и подписи сторон', (tester) async {
      await pumpScreen(tester, const DoctorChatScreen(threadId: 't1'));

      expect(find.text('Чат с врачом'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(2));
    });
  });

  group('модель', () {
    test('своя реплика показывается с приставкой «Вы»', () {
      final mine = ChatThread(
        id: 't',
        doctorName: 'Врач',
        lastMessage: 'Привет',
        lastMessageAt: DateTime(2026, 7, 21, 13, 44),
        lastMessageIsMine: true,
      );
      final theirs = ChatThread(
        id: 't',
        doctorName: 'Врач',
        lastMessage: 'Привет',
        lastMessageAt: DateTime(2026, 7, 21, 13, 44),
        lastMessageIsMine: false,
      );

      expect(mine.preview, 'Вы: Привет');
      expect(theirs.preview, 'Привет');
    });

    test('время форматируется как в макете', () {
      final thread = ChatThread(
        id: 't',
        doctorName: 'Врач',
        lastMessage: '',
        lastMessageAt: DateTime(2026, 7, 21, 13, 44),
        lastMessageIsMine: false,
      );

      expect(thread.timeLabel, '21.07, 13:44');
    });
  });

  group('контроллер переписки', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          chatsRepositoryProvider.overrideWithValue(
            const FakeChatsRepository(),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('пустая строка не отправляется', () async {
      final c = container.read(doctorChatControllerProvider.notifier);
      await c.open('t1');
      final before = container
          .read(doctorChatControllerProvider)
          .messages
          .length;

      await c.send('   ');

      expect(
        container.read(doctorChatControllerProvider).messages,
        hasLength(before),
      );
    });

    test('отправка добавляет свою реплику в конец', () async {
      final c = container.read(doctorChatControllerProvider.notifier);
      await c.open('t1');
      await c.send('Спасибо!');

      final messages = container.read(doctorChatControllerProvider).messages;
      expect(messages.last.text, 'Спасибо!');
      expect(messages.last.isMine, isTrue);
    });
  });
}
