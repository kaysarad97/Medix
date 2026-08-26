@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_chatbot_controller.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_chatbot_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_chatbot_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны для `design/для врача от клиники/Чат-бот Старт - в.ф.png` и
/// `Чат-бот - в.ф.png`.
void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpChatbot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        doctorChatbotRepositoryProvider.overrideWithValue(
          const FakeDoctorChatbotRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorChatbotScreen(),
        ),
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
      find.byType(DoctorChatbotScreen),
      matchesGoldenFile('goldens/doctor_chatbot_start.png'),
    );
  });

  testWidgets('переписка', (tester) async {
    final container = await pumpChatbot(tester);

    // Без await: ответ заглушки приходит через Future.delayed, а поддельные
    // часы теста двигает только pump. Дождаться его прямо здесь нельзя —
    // тест повиснет.
    unawaited(
      container
          .read(doctorChatbotControllerProvider.notifier)
          .send('Высчитать дозу для пациента'),
    );
    await tester.pump();
    await tester.pump(FakeDoctorChatbotRepository.delay);
    await tester.pump();

    await expectLater(
      find.byType(DoctorChatbotScreen),
      matchesGoldenFile('goldens/doctor_chatbot_conversation.png'),
    );
  });
}
