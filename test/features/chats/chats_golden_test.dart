@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/chats/presentation/providers/chats_providers.dart';
import 'package:medix/features/chats/presentation/screens/chats_list_screen.dart';
import 'package:medix/features/chats/presentation/screens/doctor_chat_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_chats_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны чатов пациента — сверка с `design/Чаты.png` и
/// `design/Чат с врачом.png` (обе 440×956).
///
/// До сих пор эти экраны были без эталона: вёрстка сверялась с макетом
/// глазами, но ничто не мешало ей поехать при следующей правке. Так уже
/// уехала подложка списка — её не было ни на одном из двух экранов, хотя
/// в макете она есть.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatsRepositoryProvider.overrideWithValue(
            const FakeChatsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: screen,
        ),
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump(FakeChatsRepository.delay);
    await tester.pump();
    await precacheScreenImages(tester);
  }

  testWidgets('chats_list соответствует эталону', (tester) async {
    await pumpScreen(tester, const ChatsListScreen());

    await expectLater(
      find.byType(ChatsListScreen),
      matchesGoldenFile('goldens/chats_list.png'),
    );
  });

  testWidgets('doctor_chat соответствует эталону', (tester) async {
    await pumpScreen(tester, const DoctorChatScreen(threadId: 't1'));
    // Историю грузит postFrameCallback — без лишнего кадра эталон снимется
    // с пустой перепиской.
    await tester.pump(FakeChatsRepository.delay);
    await tester.pump();

    await expectLater(
      find.byType(DoctorChatScreen),
      matchesGoldenFile('goldens/doctor_chat.png'),
    );
  });
}
