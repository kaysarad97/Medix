@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_patient.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_call_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';
import 'package:medix/shared/models/medix_avatars.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны звонка со стороны врача — сверка с
/// `design/для врача от клиники/Видео-звонок.png` и `.../Аудио-звонок.png`
/// (обе 440×978).
///
/// Состояния «завершен» эталонами не закрываются — как и у пациента: это
/// тот же экран под `Opacity`, а не отдельная вёрстка.
void main() {
  setUpAll(loadAppFonts);

  DoctorPatient patient(AppointmentKind kind) => DoctorPatient(
    id: 'p1',
    fullName: 'Имя Фамилия',
    heightCm: 170,
    weightKg: 77,
    age: 30,
    avatarAsset: MedixAvatars.all[2],
    appointment: DoctorAppointment(
      id: 'a1',
      patientName: 'Имя Фамилия',
      kind: kind,
      startsAt: DateTime(2026, 7, 21, 10, 30),
    ),
  );

  Future<void> pumpScreen(WidgetTester tester, AppointmentKind kind) async {
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
          doctorPatientProvider(
            'p1',
          ).overrideWith((ref) => Future.value(patient(kind))),
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

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/call_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
    await precacheScreenImages(tester);
  }

  testWidgets('doctor_video_call соответствует эталону', (tester) async {
    await pumpScreen(tester, AppointmentKind.videoCall);

    await expectLater(
      find.byType(DoctorCallScreen),
      matchesGoldenFile('goldens/doctor_video_call.png'),
    );
  });

  testWidgets('doctor_audio_call соответствует эталону', (tester) async {
    await pumpScreen(tester, AppointmentKind.audioCall);

    await expectLater(
      find.byType(DoctorCallScreen),
      matchesGoldenFile('goldens/doctor_audio_call.png'),
    );
  });
}
