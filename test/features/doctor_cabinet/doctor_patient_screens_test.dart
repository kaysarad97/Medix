import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/platform/external_url_opener.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_patient.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_appointment_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_patient_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    FakeDoctorCabinetRepository repository =
        const FakeDoctorCabinetRepository(),
    ExternalUrlOpener? urlOpener,
  }) async {
    // Оба экрана длиннее телефона по умолчанию — иначе нижние карточки не
    // строятся и проверять нечего.
    tester.view.physicalSize = const Size(440, 1440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(repository),
          externalUrlOpenerProvider.overrideWithValue(
            urlOpener ?? (_) async => true,
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

    testWidgets('очный приём открывает системный набор номера пациента', (
      tester,
    ) async {
      final opened = <Uri>[];
      await pumpScreen(
        tester,
        const DoctorPatientAppointmentScreen(patientId: 'p1'),
        repository: const _InPersonDoctorCabinetRepository(),
        urlOpener: (uri) async {
          opened.add(uri);
          return true;
        },
      );

      await tester.tap(find.text('Позвонить пациенту'));
      await tester.pump();

      expect(opened, hasLength(1));
      expect(opened.single.scheme, 'tel');
      expect(opened.single.path, '+77010000000');
    });

    testWidgets('фрилансер отменяет запись только с указанной причиной', (
      tester,
    ) async {
      final repository = _FreelancerCancellationRepository();
      await pumpScreen(
        tester,
        const DoctorPatientAppointmentScreen(patientId: 'p1'),
        repository: repository,
      );

      await tester.tap(find.byKey(const ValueKey('doctor-cancel-appointment')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const ValueKey('doctor-cancel-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('doctor-cancel-reason')),
        'Врач заболел',
      );
      await tester.pump();
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(repository.cancelledAppointmentId, 'p-p1');
      expect(repository.cancellationReason, 'Врач заболел');
      expect(
        find.byKey(const ValueKey('doctor-cancel-appointment')),
        findsNothing,
      );
    });

    testWidgets('врач отмечает неявку после начала подтверждённого приёма', (
      tester,
    ) async {
      final repository = _NoShowRepository();
      await pumpScreen(
        tester,
        const DoctorPatientAppointmentScreen(patientId: 'p1'),
        repository: repository,
      );

      // startsAt фикстуры (21 июля) в прошлом, статус confirmed — по
      // условию markAppointmentNoShow кнопка уже должна быть видна.
      expect(find.byKey(const ValueKey('doctor-mark-no-show')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('doctor-mark-no-show')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('doctor-no-show-confirm')));
      await tester.pumpAndSettle();

      expect(repository.noShowAppointmentId, 'p-p1');
      // Локальный copyWithStatus(noShow) прячет кнопку без похода на
      // сервер — markAppointmentNoShow ничего не возвращает.
      expect(find.byKey(const ValueKey('doctor-mark-no-show')), findsNothing);
    });
  });
}

class _InPersonDoctorCabinetRepository extends FakeDoctorCabinetRepository {
  const _InPersonDoctorCabinetRepository();

  @override
  Future<DoctorPatient> patient(String id) async => DoctorPatient(
    id: id,
    fullName: 'Имя Фамилия',
    heightCm: 170,
    weightKg: 77,
    age: 30,
    appointment: DoctorAppointment(
      id: 'p-$id',
      patientName: 'Имя Фамилия',
      patientId: id,
      patientPhone: '+77010000000',
      kind: AppointmentKind.inPerson,
      startsAt: DateTime(2026, 7, 21, 10, 30),
    ),
  );
}

class _FreelancerCancellationRepository extends FakeDoctorCabinetRepository {
  _FreelancerCancellationRepository() : super(isFreelancer: true);

  String? cancelledAppointmentId;
  String? cancellationReason;

  DoctorAppointment get appointment => DoctorAppointment(
    id: 'p-p1',
    patientName: 'Имя Фамилия',
    patientId: 'p1',
    kind: AppointmentKind.audioCall,
    startsAt: DateTime(2026, 7, 21, 10, 30),
    status: AppointmentStatus.confirmed,
  );

  @override
  Future<DoctorPatient> patient(String id) async => DoctorPatient(
    id: id,
    fullName: 'Имя Фамилия',
    heightCm: 170,
    weightKg: 77,
    age: 30,
    appointment: appointment,
  );

  @override
  Future<DoctorAppointment> cancelAppointment(
    String appointmentId,
    String reason,
  ) async {
    cancelledAppointmentId = appointmentId;
    cancellationReason = reason;
    return appointment.copyWithStatus(AppointmentStatus.cancelled);
  }
}

/// Специально без `isFreelancer: true`: markAppointmentNoShow не зависит
/// от роли, в отличие от cancelAppointment, — см. комментарий у
/// `canMarkNoShow` в `doctor_patient_appointment_screen.dart`.
class _NoShowRepository extends FakeDoctorCabinetRepository {
  _NoShowRepository();

  String? noShowAppointmentId;

  DoctorAppointment get appointment => DoctorAppointment(
    id: 'p-p1',
    patientName: 'Имя Фамилия',
    patientId: 'p1',
    kind: AppointmentKind.audioCall,
    startsAt: DateTime(2026, 7, 21, 10, 30),
    status: AppointmentStatus.confirmed,
  );

  @override
  Future<DoctorPatient> patient(String id) async => DoctorPatient(
    id: id,
    fullName: 'Имя Фамилия',
    heightCm: 170,
    weightKg: 77,
    age: 30,
    appointment: appointment,
  );

  @override
  Future<void> markAppointmentNoShow(String appointmentId) async {
    noShowAppointmentId = appointmentId;
  }
}
