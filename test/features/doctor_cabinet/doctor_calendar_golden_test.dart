@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_calendar_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон календаря кабинета врача — сверка с
/// `design/.../Календарь.png` (440×956). День зафиксирован: макет снят на
/// «Четверг, 21-ое июля, 2026 год», и суббота/воскресенье в этой неделе
/// должны выглядеть погашенными.
void main() {
  setUpAll(loadAppFonts);

  testWidgets('doctor_calendar_screen соответствует эталону', (tester) async {
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
          selectedCalendarDayProvider.overrideWith(
            () => _FixedDay(DateTime(2026, 7, 21)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorCalendarScreen(),
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

    await expectLater(
      find.byType(DoctorCalendarScreen),
      matchesGoldenFile('goldens/doctor_calendar_screen.png'),
    );
  });
}

class _FixedDay extends SelectedCalendarDay {
  _FixedDay(this._initial);

  final DateTime _initial;

  @override
  DateTime build() => _initial;
}
