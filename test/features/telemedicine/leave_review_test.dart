import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/leave_review_screen.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/domain/entities/doctor_review.dart';
import 'package:medix/core/widgets/rating_stars.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

/// Экран «Оставьте отзыв» по `design/Оставьте отзыв.png`.
void main() {
  setUpAll(loadAppFonts);

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(440, 1010);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorsRepositoryProvider.overrideWithValue(
            const FakeDoctorsRepository(),
          ),
          // Отсюда берётся имя, которым подписывается отзыв.
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          consultationsRepositoryProvider.overrideWithValue(
            _FakeConsultationsRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Дата фиксированная: под текстом отзыва стоит сегодняшняя.
          home: LeaveReviewScreen(doctorId: 'd1', now: DateTime(2026, 8, 10)),
        ),
      ),
    );
    await tester.pump();

    return ProviderScope.containerOf(
      tester.element(find.byType(LeaveReviewScreen)),
    );
  }

  testWidgets('рисует шапку врача, оценку и дату из макета', (tester) async {
    await pumpScreen(tester);

    expect(find.text('О враче'), findsOneWidget);
    expect(find.text('Алматы'), findsOneWidget);
    expect(find.text('Гастроэнтеролог'), findsOneWidget);
    expect(find.text('Ваша оценка: 0.0'), findsOneWidget);
    expect(find.text('Оставьте свой отзыв...'), findsOneWidget);
    expect(find.text('от 10.08.26'), findsOneWidget);
    expect(find.text('Оставить отзыв'), findsOneWidget);
  });

  testWidgets('нажатие на звезду выставляет оценку', (tester) async {
    await pumpScreen(tester);

    // Третья звезда: каждая звезда — своя кнопка.
    await tester.tap(find.byType(RatingStars).at(2));
    await tester.pump();

    expect(find.text('Ваша оценка: 3.0'), findsOneWidget);
  });

  testWidgets('отзыв уходит с оценкой, текстом и именем из профиля', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    await tester.tap(find.byType(RatingStars).at(3));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Спасибо, всё объяснил');
    await tester.tap(find.text('Оставить отзыв'));
    await tester.pump();

    final review = container.read(composedReviewsProvider).single;
    expect(review.text, 'Спасибо, всё объяснил');
    expect(review.rating, 4);
    expect(review.authorName, 'Имя Фамилия');
    expect(review.dateLabel, isNotNull);
  });

  testWidgets('пустой отзыв не отправляется', (tester) async {
    final container = await pumpScreen(tester);

    await tester.tap(find.text('Оставить отзыв'));
    await tester.pump();

    expect(container.read(composedReviewsProvider), isEmpty);
  });
}

class _FakeConsultationsRepository extends ConsultationsRepository {
  _FakeConsultationsRepository() : super(Dio());

  @override
  Future<DoctorReview> reviewDoctor(
    String doctorId, {
    required int rating,
    String? body,
  }) async => DoctorReview(
    id: 'review-1',
    authorName: 'Имя Фамилия',
    rating: rating.toDouble(),
    text: body ?? '',
    createdAt: DateTime(2026, 8, 10),
  );
}
