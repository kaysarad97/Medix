import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/subscriptions/data/repositories/subscriptions_repository.dart';
import 'package:medix/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:medix/features/subscriptions/presentation/providers/subscriptions_providers.dart';
import 'package:medix/features/subscriptions/presentation/screens/cancel_subscription_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('подтверждает отмену и показывает конец периода', (tester) async {
    final repository = _CancellationRepository();
    SubscriptionCancellation? result;
    await _pump(tester, repository, onCancelled: (value) => result = value);

    expect(find.text('Отмена подписки'), findsOneWidget);
    expect(find.text('Отменить подписку'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Отменить подписку'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 1);
    expect(result?.cancelAtPeriodEnd, isTrue);
    expect(
      find.text('Подписка отменена. Доступ сохранён до 31.08.2026'),
      findsOneWidget,
    );
  });
}

Future<void> _pump(
  WidgetTester tester,
  _CancellationRepository repository, {
  ValueChanged<SubscriptionCancellation>? onCancelled,
}) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CancelSubscriptionScreen(onCancelled: onCancelled),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _CancellationRepository extends MockSubscriptionsRepository {
  int cancelCalls = 0;

  @override
  Future<SubscriptionCancellation> cancel() async {
    cancelCalls++;
    return SubscriptionCancellation(
      periodEnd: DateTime(2026, 8, 31),
      cancelAtPeriodEnd: true,
    );
  }
}
