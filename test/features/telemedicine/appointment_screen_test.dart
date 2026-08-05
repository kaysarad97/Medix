import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/appointment_screen.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpAppointment(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AppointmentScreen(appointmentId: 'a1'),
        ),
      ),
    );
    // Врач подтягивается вторым запросом, после самой записи.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует элементы макета «Ваша Запись»', (tester) async {
    await pumpAppointment(tester);

    expect(find.text('Ваша запись'), findsNWidgets(2)); // заголовок и подпись
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('10.07, 13:30'), findsOneWidget);
    expect(find.text('Начать звонок'), findsOneWidget);
    expect(find.text('Перенести запись'), findsOneWidget);
  });

  testWidgets('чипа города на этом экране нет', (tester) async {
    await pumpAppointment(tester);

    expect(find.text('Алматы'), findsNothing);
  });

  testWidgets('формат приёма подставляется из записи', (tester) async {
    await pumpAppointment(tester);

    // «Аудио-звонок» стоит и в строке записи, и подписью на кнопке звонка.
    expect(find.text('Аудио-звонок'), findsNWidgets(2));
  });

  testWidgets('перенос записи показывает подтверждение с новым временем', (
    tester,
  ) async {
    await pumpAppointment(tester);

    await tester.tap(find.text('12:30'));
    await tester.pump();
    await tester.tap(find.text('Создать запись'));
    await tester.pump();

    expect(
      find.textContaining('Приём перенесён на 20.07, 12:30'),
      findsOneWidget,
    );
  });
}
