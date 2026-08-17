@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/user_avatar.dart';
import 'package:medix/features/calls/presentation/screens/call_screen.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны экрана звонка для сверки с `design/Видео-звонок.png` и
/// `design/Аудио-звонок.png».
///
/// Состояния «завершен» (`design/Видео-звонок завершен.png`,
/// `design/Аудио-звонок завершен.png`) не заведены отдельными эталонами:
/// это тот же экран с `Opacity` поверх и одной строкой текста — риск
/// регрессии много ниже, чем у самой раскладки.
///
/// РАСХОЖДЕНИЯ С МАКЕТОМ, ОСОЗНАННЫЕ:
///  • фото врача и самопросмотр — подложки-плейсхолдеры, как везде в
///    приложении: настоящих фото с бэкенда нет;
///  • иконка паузы — системная (`Icons.pause`), дизайнер её не экспортировал.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, {required bool video}) async {
    tester.view.physicalSize = const Size(440, 978);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          if (video)
            appointmentProvider('a1').overrideWith(
              (ref) async => Appointment(
                id: 'a1',
                specialty: 'Гастроэнтеролог',
                kind: AppointmentKind.videoCall,
                startsAt: DateTime(2026, 7, 10, 13, 30),
                doctorId: 'd1',
              ),
            ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CallScreen(appointmentId: 'a1'),
        ),
      ),
    );

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/call_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await precacheImage(
        const AssetImage('assets/images/avatars/avatar_01.png'),
        tester.element(find.byType(MaterialApp)),
      );
      // Подложка видна сквозь прозрачные углы аватара — без прекэша эталон
      // показывал бы на их месте фон экрана, а не то, что рисует код.
      await precacheImage(
        const AssetImage(UserAvatar.backgroundAsset),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
  }

  testWidgets('video_call соответствует эталону', (tester) async {
    await pumpScreen(tester, video: true);

    await expectLater(
      find.byType(CallScreen),
      matchesGoldenFile('goldens/video_call.png'),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('audio_call соответствует эталону', (tester) async {
    await pumpScreen(tester, video: false);

    await expectLater(
      find.byType(CallScreen),
      matchesGoldenFile('goldens/audio_call.png'),
    );

    await tester.pumpWidget(const SizedBox());
  });
}
