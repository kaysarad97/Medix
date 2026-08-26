@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/domain/entities/doctor_own_review.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_reviews_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/golden_images.dart';
import '../../helpers/test_fonts.dart';

/// Эталон «Отзывы о Вас» — сверка с
/// `design/для врача от клиники/Отзывы о враче.png`. Страница
/// прокручиваемая, макет экспортирован с запасом по высоте (1246) — тот же
/// приём, что и у эталона «Ваш Профиль».
void main() {
  setUpAll(loadAppFonts);

  const text =
      'Временный текст отзыва о враче. Скоро здесь будут '
      'настоящие отзывы от настощих пациентов, которые проходили '
      'консультацию или лечение у этого врача. Мы работаем только с '
      'квалифицированными специалистами с хорошим рейтингом.';

  testWidgets('doctor_reviews_screen соответствует эталону', (tester) async {
    tester.view.physicalSize = const Size(440, 1246);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorOwnReviewsProvider.overrideWith(
            (ref) => const [
              DoctorOwnReview(
                id: 'r1',
                authorName: 'Пользователь 1',
                rating: 4.5,
                text: text,
              ),
              DoctorOwnReview(
                id: 'r2',
                authorName: 'Пользователь 1',
                rating: 4.5,
                text: text,
              ),
              DoctorOwnReview(
                id: 'r3',
                authorName: 'Пользователь 1',
                rating: 4.5,
                text: text,
              ),
              DoctorOwnReview(
                id: 'r4',
                authorName: 'Пользователь 1',
                rating: 4.5,
                text: text,
              ),
              DoctorOwnReview(
                id: 'r5',
                authorName: 'Пользователь 1',
                rating: 4.5,
                text: text,
              ),
            ],
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

    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/app_bg.png'),
        tester.element(find.byType(MaterialApp)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    await tester.pump();
    await precacheScreenImages(tester);

    await expectLater(
      find.byType(DoctorReviewsScreen),
      matchesGoldenFile('goldens/doctor_reviews_screen.png'),
    );
  });
}
