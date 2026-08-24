import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_profile_settings_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

/// Свёрстан по `design/врач фрилансер/Настройки Профиля.png` — только у
/// врача-фрилансера, вход со строки «Настройки профиля» на
/// `DoctorSettingsScreen`.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) async {
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
          home: const DoctorProfileSettingsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует заголовок и поля, предзаполненные из профиля', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Настройки профиля'), findsOneWidget);
    expect(find.text('изменить фото'), findsOneWidget);

    final firstField = tester.widget<TextField>(find.byType(TextField).at(0));
    expect(firstField.controller?.text, 'Имя');
    final lastField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(lastField.controller?.text, 'Фамилия');
    final emailField = tester.widget<TextField>(find.byType(TextField).at(2));
    expect(emailField.controller?.text, 'abcefg@mail.com');

    // Поле пароля — ради формы макета, паролей в MedIx нет.
    final passwordField = tester.widget<TextField>(
      find.byType(TextField).at(3),
    );
    expect(passwordField.obscureText, isTrue);
  });
}
