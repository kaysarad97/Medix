import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_settings_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/providers/app_settings_provider.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool showFreelancerRows = false,
  }) {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorSettingsScreen(showFreelancerRows: showFreelancerRows),
        ),
      ),
    );
  }

  testWidgets('рисует переключатель уведомлений, язык и связь с нами', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.pump();

    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Уведомления'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Язык приложения'), findsOneWidget);
    expect(find.text('Қазақша'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Свяжитесь с нами'), findsOneWidget);
    // Строк пациентских настроек — «Настройки профиля», «Банковские
    // данные» — в макете врача нет.
    expect(find.text('Настройки профиля'), findsNothing);
    expect(find.text('Банковские данные'), findsNothing);
  });

  testWidgets('showFreelancerRows добавляет настройки профиля и банк', (
    tester,
  ) async {
    await pumpScreen(tester, showFreelancerRows: true);
    await tester.pump();

    expect(find.text('Настройки профиля'), findsOneWidget);
    expect(find.text('Банковские данные'), findsOneWidget);
  });

  testWidgets('переключает язык через общий с пациентом провайдер', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Қазақша'));
    await tester.pump();

    expect(container.read(appSettingsProvider).language?.code, 'kk');
  });
}
