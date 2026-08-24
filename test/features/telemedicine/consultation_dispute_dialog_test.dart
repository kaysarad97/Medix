import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/telemedicine/presentation/widgets/consultation_dispute_dialog.dart';
import 'package:medix/l10n/app_localizations.dart';

void main() {
  testWidgets('не отправляет пустую причину и возвращает введённый текст', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showConsultationDisputeDialog(context);
            },
            child: const Text('Открыть'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('consultation-dispute-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('consultation-dispute-reason')),
      '  Связь прервалась  ',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(result, 'Связь прервалась');
  });
}
