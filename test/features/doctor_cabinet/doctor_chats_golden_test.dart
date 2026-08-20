@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_chats_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_chat_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны чатов кабинета врача — сверка с
/// `design/для врача от клиники/Чаты с пациентами.png` (440×956) и
/// `design/врач прилансер/Чат с пациентом.png` (440×978).
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
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
    await tester.pump();
    await precacheScreenImages(tester);
  }

  testWidgets('doctor_chats_screen соответствует эталону', (tester) async {
    await pumpScreen(tester, const DoctorChatsScreen(), const Size(440, 956));

    await expectLater(
      find.byType(DoctorChatsScreen),
      matchesGoldenFile('goldens/doctor_chats_screen.png'),
    );
  });

  testWidgets('doctor_patient_chat_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const DoctorPatientChatScreen(threadId: 'pc1'),
      const Size(440, 978),
    );
    // Историю грузит postFrameCallback — без второго кадра эталон снимется
    // с пустой перепиской.
    await tester.pump();

    await expectLater(
      find.byType(DoctorPatientChatScreen),
      matchesGoldenFile('goldens/doctor_patient_chat_screen.png'),
    );
  });
}
