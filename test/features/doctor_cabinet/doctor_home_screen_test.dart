import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_profile.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/regular_patient.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_home_screen.dart';
import 'package:medix/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/appointment.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool? showAdminTile = true,
    bool isFreelancer = false,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationsCountProvider.overrideWith((ref) => 0),
          // Синхронно, не через мок-репозиторий: `Future.delayed` создаёт
          // таймер вне `runAsync`, тест падает на «timersPending».
          doctorUpcomingAppointmentsProvider.overrideWith(
            (ref) => [
              DoctorAppointment(
                id: 'a1',
                patientName: 'Пациент Имя Фамилия',
                kind: AppointmentKind.videoCall,
                startsAt: DateTime(2026, 8, 13, 10, 30),
              ),
            ],
          ),
          doctorRegularPatientsProvider.overrideWith(
            (ref) => const [
              RegularPatient(id: 'p1', fullName: 'Ф. Имя Отчество'),
              RegularPatient(id: 'p2', fullName: 'Ф. Имя Отчество'),
            ],
          ),
          doctorOwnProfileProvider.overrideWith(
            (ref) async => DoctorOwnProfile(
              fullName: 'Имя Фамилия',
              doctorId: 'd1',
              status: 'активен',
              rating: 4.5,
              specialization: '',
              experience: '',
              category: '',
              address: '',
              onlineConsultations: true,
              phone: '',
              email: 'doctor@medix.kz',
              isFreelancer: isFreelancer,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorHomeScreen(showAdminTile: showAdminTile),
        ),
      ),
    );
  }

  testWidgets('рисует приветствие, плитки и запись', (tester) async {
    await pumpScreen(tester);
    await tester.pump();

    expect(find.textContaining('Здравствуйте'), findsOneWidget);
    expect(find.text('Здравствуйте, Имя Фамилия!'), findsOneWidget);
    expect(find.text('График\nработы'), findsOneWidget);
    expect(find.text('История\nзаписей'), findsOneWidget);
    expect(find.text('Аналитика активности'), findsOneWidget);
    expect(find.text('Мои сообщения'), findsOneWidget);
    expect(find.text('Постоянные пациенты'), findsOneWidget);
    expect(find.text('Пациент Имя Фамилия'), findsOneWidget);
    expect(find.text('Администрация'), findsOneWidget);
  });

  testWidgets('без showAdminTile плитка администрации не рисуется', (
    tester,
  ) async {
    await pumpScreen(tester, showAdminTile: false);
    await tester.pump();

    expect(find.text('Администрация'), findsNothing);
  });

  testWidgets('серверный профиль фрилансера скрывает администрацию', (
    tester,
  ) async {
    await pumpScreen(tester, showAdminTile: null, isFreelancer: true);
    await tester.pump();

    expect(find.text('Администрация'), findsNothing);
  });
}
