import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/platform/external_url_opener.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_appointment.dart';
import 'package:medix/features/doctor_cabinet/presentation/widgets/doctor_appointment_files_card.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('показывает файлы записи и открывает серверную ссылку', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalUrlOpenerProvider.overrideWithValue((uri) async {
            openedUri = uri;
            return true;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DoctorAppointmentFilesCard(
              files: [
                DoctorAppointmentFile(
                  id: 'file-1',
                  downloadUrl: 'https://storage.example/file-1?signature=test',
                  createdAt: DateTime(2026, 8, 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Файлы консультации'), findsOneWidget);
    expect(find.text('Вложение 1'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('doctor-appointment-file-file-1')),
    );
    await tester.pump();

    expect(
      openedUri,
      Uri.parse('https://storage.example/file-1?signature=test'),
    );
  });
}
