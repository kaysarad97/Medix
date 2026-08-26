import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_chats_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_chat_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
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
    await tester.pump();
    await tester.pump();
  }

  group('чаты с пациентами', () {
    testWidgets('рисует бота, переписки и приставку «Вы»', (tester) async {
      await pumpScreen(tester, const DoctorChatsScreen());

      expect(find.text('Все чаты'), findsOneWidget);
      expect(find.text('Чат с Medi-Bot'), findsOneWidget);
      expect(find.text('Чем я могу помочь?'), findsOneWidget);
      expect(find.text('Имя Фамилия'), findsNWidgets(2));
      // Своя реплика подписана «Вы: », чужая — как есть.
      expect(
        find.text('Вы: Спасибо за обращение, на здоровье!'),
        findsOneWidget,
      );
      expect(find.text('не прочитано'), findsOneWidget);
      expect(find.text('прочитано'), findsOneWidget);
    });

    testWidgets('поиск оставляет только совпавшие переписки', (tester) async {
      await pumpScreen(tester, const DoctorChatsScreen());

      await tester.enterText(find.byType(TextField), 'анализы');
      await tester.pump();

      expect(find.text('Вы: Спасибо за обращение, на здоровье!'), findsNothing);
      // Бот закреплён и поиску не подчиняется — он не переписка.
      expect(find.text('Чат с Medi-Bot'), findsOneWidget);
    });
  });

  group('чат с пациентом', () {
    testWidgets('показывает историю переписки', (tester) async {
      await pumpScreen(tester, const DoctorPatientChatScreen(threadId: 'pc1'));
      await tester.pump();

      expect(find.text('Чат с пациентом'), findsOneWidget);
      expect(
        find.text('Здравствуйте! Как Вы себя чувствуете сегодня?'),
        findsOneWidget,
      );
      expect(find.text('Спасибо, все хорошо!'), findsOneWidget);
    });

    testWidgets('отправленная реплика встаёт в конец', (tester) async {
      await pumpScreen(tester, const DoctorPatientChatScreen(threadId: 'pc1'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Жду Вас на приёме');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump();

      expect(find.text('Жду Вас на приёме'), findsOneWidget);
    });
  });
}
