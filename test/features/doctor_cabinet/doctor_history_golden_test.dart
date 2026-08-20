@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_history_screen.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_past_appointment_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталоны «Истории записей» и «О прошлой записи» — сверка с
/// `design/для врача от клиники/История записей.png` и
/// `.../О прошлой записи.png` (обе 440×956).
///
/// День зафиксирован на 21 июля 2026: макет снят на этой неделе, и
/// суббота с воскресеньем в ней должны выглядеть погашенными.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
          ),
          selectedHistoryDayProvider.overrideWith(
            () => _FixedDay(DateTime(2026, 7, 21)),
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

  testWidgets('doctor_history_screen соответствует эталону', (tester) async {
    await pumpScreen(tester, const DoctorHistoryScreen());

    await expectLater(
      find.byType(DoctorHistoryScreen),
      matchesGoldenFile('goldens/doctor_history_screen.png'),
    );
  });

  testWidgets('doctor_past_appointment_screen соответствует эталону', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const DoctorPastAppointmentScreen(appointmentId: 'h1'),
    );

    await expectLater(
      find.byType(DoctorPastAppointmentScreen),
      matchesGoldenFile('goldens/doctor_past_appointment_screen.png'),
    );
  });
}

class _FixedDay extends SelectedHistoryDay {
  _FixedDay(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
