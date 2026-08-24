import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/icon_chip.dart';
import 'package:medix/features/calls/presentation/screens/call_screen.dart';
import 'package:medix/features/calls/data/call_media_session.dart';
import 'package:medix/features/calls/presentation/providers/call_session_controller.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpCall(
    WidgetTester tester, {
    bool video = false,
    String? consultationId,
    _DisputeRepository? consultations,
  }) async {
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
          if (consultations == null)
            consultationForAppointmentProvider(
              'a1',
            ).overrideWith((ref) async => null),
          if (consultations != null) ...[
            consultationsRepositoryProvider.overrideWithValue(consultations),
            callSessionControllerFactoryProvider.overrideWithValue(
              () =>
                  CallSessionController(consultations, _FakeCallMediaSession()),
            ),
          ],
          if (video || consultationId != null)
            appointmentProvider('a1').overrideWith(
              (ref) async => Appointment(
                id: 'a1',
                specialty: 'Гастроэнтеролог',
                kind: video
                    ? AppointmentKind.videoCall
                    : AppointmentKind.audioCall,
                startsAt: DateTime(2026, 7, 10, 13, 30),
                doctorId: 'd1',
                consultationId: consultationId,
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
    // Врач подтягивается вторым запросом, после самой записи.
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapHangUp(WidgetTester tester) async {
    await tester.tap(
      find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is AppIcon && w.icon == MedixIcon.callDecline,
        ),
        matching: find.byType(InkWell),
      ),
    );
    await tester.pump();
  }

  testWidgets('аудио-звонок (формат из записи по умолчанию)', (tester) async {
    await pumpCall(tester);

    expect(find.text('Аудио-звонок'), findsOneWidget);
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);
    expect(find.text('Вызов завершен'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('видео-звонок показывает соответствующий заголовок', (
    tester,
  ) async {
    await pumpCall(tester, video: true);

    expect(find.text('Видео-звонок'), findsOneWidget);
    expect(find.text('Имя Фамилия'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('сброс звонка показывает «Вызов завершен»', (tester) async {
    await pumpCall(tester, video: true);

    await tapHangUp(tester);

    expect(find.text('Вызов завершен'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('таймер идёт по секундам, пока звонок активен', (tester) async {
    await pumpCall(tester);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('0:03'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('повторный сброс после завершения не падает', (tester) async {
    await pumpCall(tester, video: true);

    await tapHangUp(tester);
    expect(find.text('Вызов завершен'), findsOneWidget);

    // Второе нажатие ведёт `Navigator.maybePop()` — в этом дереве попадать
    // некуда, но и падать не должно.
    await tapHangUp(tester);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('после звонка отправляет спор по consultation id', (
    tester,
  ) async {
    final repository = _DisputeRepository();
    await pumpCall(tester, consultationId: 'c1', consultations: repository);
    await tester.pump();

    await tapHangUp(tester);
    await tester.tap(find.text('Сообщить о проблеме'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('consultation-dispute-reason')),
      'Связь прервалась',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('consultation-dispute-submit')));
    await tester.pumpAndSettle();

    expect(repository.disputedConsultationId, 'c1');
    expect(repository.disputeReason, 'Связь прервалась');
    expect(find.text('Обращение отправлено'), findsOneWidget);
  });

  testWidgets('находит консультацию по appointment id и подключает звонок', (
    tester,
  ) async {
    final repository = _DisputeRepository();
    await pumpCall(tester, consultations: repository);
    await tester.pump();
    await tester.pump();

    expect(repository.lookedUpAppointmentId, 'a1');
    expect(repository.joinedConsultationId, 'c1');

    await tester.pumpWidget(const SizedBox());
  });
}

class _DisputeRepository extends ConsultationsRepository {
  _DisputeRepository() : super(Dio());

  String? disputedConsultationId;
  String? disputeReason;
  String? lookedUpAppointmentId;
  String? joinedConsultationId;

  @override
  Future<Consultation?> consultationForAppointment(String appointmentId) async {
    lookedUpAppointmentId = appointmentId;
    return const Consultation(
      id: 'c1',
      appointmentId: 'a1',
      status: ConsultationStatus.scheduled,
    );
  }

  @override
  Future<ConsultationJoin> join(String consultationId) async {
    joinedConsultationId = consultationId;
    return ConsultationJoin(
      roomId: 'room',
      webSocketTicket: 'ws',
      videoToken: 'video',
      videoServerUrl: 'wss://livekit.example',
      mode: ConsultationMode.audio,
      expiresAt: DateTime(2026, 8, 24, 12),
    );
  }

  @override
  Future<ConsultationDispute> dispute(
    String consultationId,
    String reason,
  ) async {
    disputedConsultationId = consultationId;
    disputeReason = reason;
    return ConsultationDispute(
      id: 'd1',
      consultationId: consultationId,
      raisedBy: 'patient',
      reason: reason,
      status: ConsultationDisputeStatus.open,
      createdAt: DateTime(2026, 8, 24),
    );
  }
}

class _FakeCallMediaSession extends CallMediaSession {
  var _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  bool get microphoneEnabled => _connected;

  @override
  bool get cameraEnabled => false;

  @override
  CallVideoFeed? get localVideo => null;

  @override
  CallVideoFeed? get remoteVideo => null;

  @override
  Future<void> connect(
    ConsultationJoin join, {
    required bool enableVideo,
  }) async {
    _connected = true;
    notifyListeners();
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    notifyListeners();
  }

  @override
  Future<void> setCameraEnabled(bool enabled) async {}

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {}
}
