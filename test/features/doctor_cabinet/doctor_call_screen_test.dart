import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/call_controls.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_call_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 978);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
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
          home: const DoctorCallScreen(patientId: 'p1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует таймер, имя пациента и кнопки', (tester) async {
    await pumpScreen(tester);

    // Фейк отдаёт аудио-звонок — заголовок и перечёркнутая камера.
    expect(find.text('Аудио-звонок'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.byType(CallControls), findsOneWidget);
    expect(find.text('Вызов завершен'), findsNothing);
  });

  testWidgets('сброс переводит экран в «Вызов завершен»', (tester) async {
    await pumpScreen(tester);

    // Кнопка сброса — единственная розовая в ромбе.
    final controls = tester.widget<CallControls>(find.byType(CallControls));
    expect(controls.hangUpColor, DoctorCallScreen.hangUpColor);

    controls.onHangUp();
    await tester.pump();

    expect(find.text('Вызов завершен'), findsOneWidget);
  });
}
