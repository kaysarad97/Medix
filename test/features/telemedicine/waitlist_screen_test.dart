import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/telemedicine/data/repositories/doctors_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_schedule.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/waitlist_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('показывает врача и активное ожидание', (tester) async {
    final repository = _WaitlistRepository(hasOffer: false);
    await _pump(tester, repository);

    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('Ожидаем свободное время'), findsOneWidget);
    expect(find.text('Записаться'), findsNothing);
  });

  testWidgets('принимает предложенный слот и отдаёт запись', (tester) async {
    final repository = _WaitlistRepository(hasOffer: true);
    Appointment? claimed;
    await _pump(
      tester,
      repository,
      onAppointmentClaimed: (value) => claimed = value,
    );

    await tester.tap(find.text('Записаться'));
    await tester.pumpAndSettle();

    expect(repository.claimedSlotId, 'slot-1');
    expect(claimed?.id, 'appointment-1');
  });

  testWidgets('выходит из листа и обновляет список', (tester) async {
    final repository = _WaitlistRepository(hasOffer: false);
    await _pump(tester, repository);

    await tester.tap(find.text('Выйти из листа ожидания'));
    await tester.pumpAndSettle();

    expect(repository.leftEntryId, 'wait-1');
    expect(find.text('Вы пока не ожидаете свободного времени'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _WaitlistRepository repository, {
  ValueChanged<Appointment>? onAppointmentClaimed,
}) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [doctorsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WaitlistScreen(onAppointmentClaimed: onAppointmentClaimed),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _WaitlistRepository extends MockDoctorsRepository {
  _WaitlistRepository({required this.hasOffer});

  final bool hasOffer;
  bool active = true;
  String? leftEntryId;
  String? claimedSlotId;

  @override
  Future<List<WaitlistEntry>> waitlistEntries() async => active
      ? [
          WaitlistEntry(
            id: 'wait-1',
            doctorId: 'doctor-1',
            status: WaitlistEntryStatus.active,
            offeredSlotId: hasOffer ? 'slot-1' : null,
          ),
        ]
      : const [];

  @override
  Future<Doctor> doctor(String id) async => const Doctor(
    id: 'doctor-1',
    fullName: 'Имя Фамилия',
    specialty: 'Терапевт',
    rating: 5,
  );

  @override
  Future<void> leaveWaitlist(String entryId) async {
    leftEntryId = entryId;
    active = false;
  }

  @override
  Future<Appointment> claimWaitlistOffer({
    required String slotId,
    required AppointmentKind kind,
    String? familyMemberId,
  }) async {
    claimedSlotId = slotId;
    active = false;
    return Appointment(
      id: 'appointment-1',
      specialty: 'Терапевт',
      kind: kind,
      startsAt: DateTime.utc(2026, 8, 22, 10),
      doctorId: 'doctor-1',
    );
  }
}
