import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/platform/external_url_opener.dart';
import 'package:medix/core/router/routes.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_services/data/repositories/lab_api_repository.dart';
import 'package:medix/features/lab_services/domain/entities/lab_workflow.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_services_providers.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_results_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  test('семейный маршрут безопасно кодирует идентификатор', () {
    expect(
      Routes.labResultsForFamily('family member/1'),
      '/lab-results?family_member_id=family+member%2F1',
    );
  });

  testWidgets('показывает результаты и открывает серверную download-ссылку', (
    tester,
  ) async {
    final repository = _LabResultsRepository(
      resultItems: [
        LabResultFile(
          id: 'result-1',
          labOrderId: 'order-1',
          createdAt: DateTime(2026, 8, 22, 14, 30),
        ),
      ],
    );
    Uri? openedUri;

    await _pump(
      tester,
      repository,
      opener: (uri) async {
        openedUri = uri;
        return true;
      },
    );

    expect(find.text('Результат анализа'), findsOneWidget);
    expect(find.text('Заказ order-1'), findsOneWidget);
    expect(find.text('Получен 22.08.2026, 14:30'), findsOneWidget);

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(repository.downloadedResultId, 'result-1');
    expect(openedUri, Uri.parse('https://storage.example/result-1.pdf'));
  });

  testWidgets('показывает пустое состояние без готовых результатов', (
    tester,
  ) async {
    await _pump(tester, _LabResultsRepository(resultItems: const []));

    expect(find.text('Готовых результатов пока нет'), findsOneWidget);
    expect(find.text('Открыть'), findsNothing);
  });

  testWidgets('запрашивает результаты выбранного члена семьи', (tester) async {
    final repository = _LabResultsRepository(resultItems: const []);

    await _pump(tester, repository, familyMemberId: 'family-1');

    expect(repository.requestedFamilyMemberId, 'family-1');
  });

  testWidgets('сообщает об ошибке, если файл невозможно открыть', (
    tester,
  ) async {
    await _pump(
      tester,
      _LabResultsRepository(
        resultItems: [
          LabResultFile(
            id: 'result-1',
            labOrderId: 'order-1',
            createdAt: DateTime(2026, 8, 22),
          ),
        ],
      ),
      opener: (_) async => false,
    );

    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось открыть файл результата'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _LabResultsRepository repository, {
  ExternalUrlOpener? opener,
  String? familyMemberId,
}) async {
  tester.view.physicalSize = const Size(440, 956);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(top: 62);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        labApiRepositoryProvider.overrideWithValue(repository),
        externalUrlOpenerProvider.overrideWithValue(
          opener ?? (_) async => true,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LabResultsScreen(familyMemberId: familyMemberId),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _LabResultsRepository extends LabApiRepository {
  _LabResultsRepository({required this.resultItems}) : super(Dio());

  final List<LabResultFile> resultItems;
  String? downloadedResultId;
  String? requestedFamilyMemberId;

  @override
  Future<List<LabResultFile>> results({String? familyMemberId}) async {
    requestedFamilyMemberId = familyMemberId;
    return resultItems;
  }

  @override
  Future<LabResultDownload> resultDownload(String resultId) async {
    downloadedResultId = resultId;
    return LabResultDownload(
      url: 'https://storage.example/$resultId.pdf',
      expiresAt: DateTime(2026, 8, 22, 15),
    );
  }
}
