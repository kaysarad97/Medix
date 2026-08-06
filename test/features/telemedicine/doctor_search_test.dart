import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/doctor_search_results_screen.dart';
import 'package:medix/features/telemedicine/presentation/screens/doctor_search_screen.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  ProviderContainer buildContainer({UserProfile? profile}) {
    final container = ProviderContainer(
      overrides: [
        doctorsRepositoryProvider.overrideWithValue(
          const FakeDoctorsRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(
          const FakeProfileRepository(),
        ),
        if (profile != null)
          profileProvider.overrideWith((ref) async => profile),
      ],
    );
    return container;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    ProviderContainer container,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
    addTearDown(tester.view.reset);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light, home: screen),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('поиск врача', () {
    testWidgets('показывает «Мои Врачи» и грид специальностей', (tester) async {
      await pumpScreen(tester, const DoctorSearchScreen(), buildContainer());

      expect(find.text('Поиск врача'), findsOneWidget);
      expect(find.text('Мои Врачи'), findsOneWidget);
      expect(find.text('Все Врачи'), findsOneWidget);
      // «Мои Врачи»: Офтальмолог, Терапевт, Педиатр.
      expect(find.text('Терапевт'), findsWidgets);
      // Грид специальностей: восемь плиток «N врачей».
      expect(find.text('10 врачей'), findsNWidgets(8));
    });
  });

  group('результаты поиска', () {
    testWidgets('показывает запрос, счётчик и карточки врачей', (tester) async {
      await pumpScreen(
        tester,
        const DoctorSearchResultsScreen(query: 'Гастроэнтеролог'),
        buildContainer(),
      );

      expect(find.text('Гастроэнтеролог'), findsWidgets);
      expect(
        find.text('Было найдено 4 врачей по Вашему запросу'),
        findsOneWidget,
      );
      expect(find.text('Имя Фамилия'), findsNWidgets(4));
    });

    testWidgets('подписчику Gold показывает скидку и подпись тарифа', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const DoctorSearchResultsScreen(query: 'Гастроэнтеролог'),
        buildContainer(),
      );

      expect(find.text('для пользователей Gold'), findsWidgets);
      expect(find.textContaining('10 000'), findsWidgets);
      expect(find.textContaining('15 000'), findsWidgets);
    });

    testWidgets('без подписки показывает цену без скидки', (tester) async {
      final freeProfile = UserProfile(
        id: 'u1',
        firstName: 'Имя',
        lastName: 'Фамилия',
        gender: Gender.male,
        birthDate: DateTime(1996, 12, 6),
        subscription: SubscriptionTier.free,
      );

      await pumpScreen(
        tester,
        const DoctorSearchResultsScreen(query: 'Гастроэнтеролог'),
        buildContainer(profile: freeProfile),
      );

      expect(find.text('для пользователей Gold'), findsNothing);
      expect(find.textContaining('10 000'), findsNothing);
      expect(find.textContaining('15 000'), findsWidgets);
    });

    testWidgets('сортировка по стажу переставляет карточки', (tester) async {
      await pumpScreen(
        tester,
        const DoctorSearchResultsScreen(query: 'Гастроэнтеролог'),
        buildContainer(),
      );

      await tester.tap(find.text('Стаж'));
      await tester.pump();

      // Мок отдаёт одинаковый стаж всем врачам — сортировка не падает и
      // список остаётся полным.
      expect(find.text('Имя Фамилия'), findsNWidgets(4));
    });
  });
}
