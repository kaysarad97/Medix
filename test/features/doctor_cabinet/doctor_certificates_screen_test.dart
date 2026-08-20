import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_certificates_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester, {bool showUploadRow = false}) {
    return tester.pumpWidget(
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
          home: DoctorCertificatesScreen(showUploadRow: showUploadRow),
        ),
      ),
    );
  }

  testWidgets('рисует заголовок и сетку сертификатов', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ваши сертификаты'), findsOneWidget);
    expect(find.text('Документ 1.pdf'), findsOneWidget);
    expect(find.text('Документ 2.pdf'), findsOneWidget);
    expect(find.text('Загрузить Сертификат'), findsNothing);
  });

  testWidgets('showUploadRow добавляет строку загрузки', (tester) async {
    await pumpScreen(tester, showUploadRow: true);
    await tester.pump();
    await tester.pump();

    expect(find.text('Загрузить Сертификат'), findsOneWidget);
  });
}
