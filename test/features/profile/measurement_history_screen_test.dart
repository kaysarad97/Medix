import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/data/repositories/profile_repository.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/profile/presentation/screens/measurement_history_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('показывает график, последнее значение и историю', (
    tester,
  ) async {
    final repository = _HistoryRepository();
    await _pump(tester, repository);

    expect(find.text('Вес'), findsOneWidget);
    expect(find.text('78 kg'), findsNWidgets(2));
    expect(find.byKey(const Key('measurement-history-chart')), findsOneWidget);
    expect(find.text('01.08.2026'), findsOneWidget);
    expect(repository.from, DateTime.utc(2026, 7, 2));
    expect(repository.to, DateTime.utc(2026, 8, 1));
  });

  testWidgets('переключатель периода перезапрашивает сервер', (tester) async {
    final repository = _HistoryRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('90 дн.'));
    await tester.pumpAndSettle();

    expect(repository.calls, 2);
    expect(repository.from, DateTime.utc(2026, 5, 3));
  });
}

Future<void> _pump(WidgetTester tester, _HistoryRepository repository) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MeasurementHistoryScreen(
          kind: MeasurementKind.weight,
          now: DateTime.utc(2026, 8, 1),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _HistoryRepository extends MockProfileRepository {
  int calls = 0;
  DateTime? from;
  DateTime? to;

  @override
  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  }) async {
    calls++;
    this.from = from;
    this.to = to;
    return [
      MeasurementPoint(
        id: 'older',
        kind: kind,
        value: 76,
        unit: 'kg',
        measuredAt: DateTime.utc(2026, 7, 1),
      ),
      MeasurementPoint(
        id: 'latest',
        kind: kind,
        value: 78,
        unit: 'kg',
        measuredAt: DateTime.utc(2026, 8, 1),
      ),
    ];
  }
}
