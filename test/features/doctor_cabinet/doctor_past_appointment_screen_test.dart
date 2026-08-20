import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_past_appointment_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
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
          home: const DoctorPastAppointmentScreen(appointmentId: 'h1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует вид записи, пациента и блок заключения', (tester) async {
    await pumpScreen(tester);

    // Заголовок экрана в макете — тот же, что у списка.
    expect(find.text('История записей'), findsOneWidget);
    expect(find.text('Аудио-звонок'), findsOneWidget);
    expect(find.text('С Имя Фамилия'), findsOneWidget);
    expect(find.text('10.07, 13:30'), findsOneWidget);
    expect(find.text('Профиль пациента'), findsOneWidget);
    expect(find.text('Об Имя Фамилия'), findsOneWidget);
    expect(find.text('Заключение от 10.07.26'), findsOneWidget);
    expect(find.text('Загрузить заключение'), findsOneWidget);
  });

  testWidgets('без заключения показывает объяснение из макета', (tester) async {
    await pumpScreen(tester);

    expect(
      find.textContaining('загрузите заключение о пациенте'),
      findsOneWidget,
    );
  });
}
