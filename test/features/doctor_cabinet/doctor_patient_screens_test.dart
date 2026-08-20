import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_appointment_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    // Оба экрана длиннее телефона по умолчанию — иначе нижние карточки не
    // строятся и проверять нечего.
    tester.view.physicalSize = const Size(440, 1440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

  group('профиль пациента', () {
    testWidgets('рисует шапку, подтверждение записи и анализы', (tester) async {
      await pumpScreen(tester, const DoctorPatientScreen(patientId: 'p1'));

      expect(find.text('О пациенте'), findsOneWidget);
      expect(find.text('Имя Фамилия'), findsOneWidget);
      // Шапка: рост, вес, возраст.
      expect(find.text('170 см'), findsOneWidget);
      expect(find.text('77 кг'), findsOneWidget);
      expect(find.text('30 лет'), findsOneWidget);

      expect(find.text('Подтвердите запись'), findsOneWidget);
      expect(find.text('21 Июля, Вторник в'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
      expect(find.text('Написать пациенту'), findsOneWidget);

      expect(find.text('Анализы пациента'), findsOneWidget);
    });

    testWidgets('заключения нет — стоит объяснение из макета', (tester) async {
      await pumpScreen(tester, const DoctorPatientScreen(patientId: 'p1'));

      expect(find.text('Об Имя Фамилия'), findsOneWidget);
      expect(
        find.textContaining('загрузите заключение о пациенте'),
        findsOneWidget,
      );
    });
  });

  group('запись с пациентом', () {
    testWidgets('рисует шапку, строку записи и пару кнопок', (tester) async {
      await pumpScreen(
        tester,
        const DoctorPatientAppointmentScreen(patientId: 'p1'),
      );

      expect(find.text('Ваша запись'), findsNWidgets(2)); // заголовок и подпись
      expect(find.text('Аудио-звонок'), findsNWidgets(2)); // строка и кнопка
      expect(find.text('Начать звонок'), findsOneWidget);
      expect(find.text('Чат с пациентом'), findsOneWidget);
      expect(find.text('21.07, 10:30'), findsOneWidget);
    });
  });
}
