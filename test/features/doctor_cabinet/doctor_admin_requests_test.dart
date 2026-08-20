import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_answer_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_request_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_admin_requests_screen.dart';
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

  group('заявка в администрацию', () {
    testWidgets('сначала показывает пять частых вопросов', (tester) async {
      await pumpScreen(tester, const DoctorAdminRequestScreen());

      expect(find.text('Часто задаваемые вопросы:'), findsOneWidget);
      expect(find.text('Нужно перенести запись'), findsOneWidget);
      expect(find.text('Нужно отменить запись'), findsOneWidget);
      expect(find.text('Ухожу в отпуск'), findsOneWidget);
      expect(find.text('Ухожу с места работы'), findsOneWidget);
      expect(find.text('Другое'), findsOneWidget);
      // Форма появляется только после выбора темы.
      expect(find.text('Отправить заявку'), findsNothing);
    });

    testWidgets('после выбора темы открывается поле и кнопка', (tester) async {
      await pumpScreen(tester, const DoctorAdminRequestScreen());

      await tester.tap(find.text('Ухожу в отпуск'));
      await tester.pump();

      expect(find.text('Тема заявки:'), findsOneWidget);
      expect(find.text('Часто задаваемые вопросы:'), findsNothing);
      expect(find.text('Опишите проблему...'), findsOneWidget);
      expect(find.text('Приложить файл'), findsOneWidget);
      expect(find.text('Отправить заявку'), findsOneWidget);
    });

    testWidgets('дата под текстом появляется вместе с текстом', (tester) async {
      await pumpScreen(tester, const DoctorAdminRequestScreen());

      await tester.tap(find.text('Другое'));
      await tester.pump();
      expect(find.textContaining('от '), findsNothing);

      await tester.enterText(find.byType(TextField), 'Прошу перенести приём');
      await tester.pump();

      expect(find.textContaining('от '), findsOneWidget);
    });
  });

  group('мои заявки', () {
    testWidgets('рисует карточки заявок и кнопку создания', (tester) async {
      await pumpScreen(tester, const DoctorAdminRequestsScreen());

      expect(find.text('Мои заявки'), findsOneWidget);
      expect(find.text('Нужно перенести запись'), findsOneWidget);
      expect(find.text('Ухожу в отпуск'), findsOneWidget);
      expect(find.text('от 10.08.26'), findsNWidgets(2));
      expect(find.text('Создать новую заявку'), findsOneWidget);
    });
  });

  group('ответ от админа', () {
    testWidgets('показывает тему, запрос и ответ', (tester) async {
      await pumpScreen(tester, const DoctorAdminAnswerScreen(requestId: 'ar1'));

      expect(find.text('Заявка в администрацию'), findsOneWidget);
      expect(find.text('Нужно перенести запись'), findsOneWidget);
      expect(find.textContaining('Временный текст запроса.'), findsOneWidget);
      expect(find.text('Ответ администрации:'), findsOneWidget);
      expect(find.text('Временный текст ответа.'), findsOneWidget);
    });

    testWidgets('без ответа показывает объяснение, а не пустоту', (
      tester,
    ) async {
      await pumpScreen(tester, const DoctorAdminAnswerScreen(requestId: 'ar2'));

      expect(find.text('Ответ администрации:'), findsOneWidget);
      expect(find.text('Администрация пока не ответила'), findsOneWidget);
    });
  });
}
