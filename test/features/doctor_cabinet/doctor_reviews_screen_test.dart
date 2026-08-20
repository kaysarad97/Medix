import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_reviews_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(WidgetTester tester) {
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
          home: const DoctorReviewsScreen(),
        ),
      ),
    );
  }

  testWidgets('рисует заголовок, топ и список отзывов', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Отзывы'), findsOneWidget);
    expect(find.text('Топ отзывов'), findsOneWidget);
    // FakeDoctorCabinetRepository отдаёт всего 2 отзыва — оба уходят в топ,
    // «Остальные отзывы» не рисуется.
    expect(find.text('Остальные отзывы'), findsNothing);
    expect(find.text('Пользователь 1'), findsWidgets);
  });
}
