import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/features/telemedicine/presentation/providers/telemedicine_providers.dart';
import 'package:medix/features/telemedicine/presentation/screens/appointment_screen.dart';
import 'package:medix/l10n/app_localizations.dart';
import 'package:medix/shared/models/gender.dart';
import 'package:medix/shared/models/subscription_tier.dart';

import '../../helpers/fake_doctors_repository.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpAppointment(
    WidgetTester tester, {
    UserProfile? profile,
  }) async {
    tester.view.physicalSize = const Size(440, 1300);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 62);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
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
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppointmentScreen(appointmentId: 'a1'),
        ),
      ),
    );
    // Врач подтягивается вторым запросом, после самой записи, а профиль —
    // третьим: `_Content` начинает следить за ним только после того, как
    // и запись, и врач уже готовы.
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('рисует элементы макета «Ваша Запись»', (tester) async {
    await pumpAppointment(tester);

    expect(find.text('Ваша запись'), findsNWidgets(2)); // заголовок и подпись
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('10.07, 13:30'), findsOneWidget);
    expect(find.text('Начать звонок'), findsOneWidget);
    expect(find.text('Перенести запись'), findsOneWidget);
  });

  testWidgets('чипа города на этом экране нет', (tester) async {
    await pumpAppointment(tester);

    expect(find.text('Алматы'), findsNothing);
  });

  testWidgets('формат приёма подставляется из записи', (tester) async {
    await pumpAppointment(tester);

    // «Аудио-звонок» стоит и в строке записи, и подписью на кнопке звонка.
    expect(find.text('Аудио-звонок'), findsNWidgets(2));
  });

  testWidgets('перенос записи показывает подтверждение с новым временем', (
    tester,
  ) async {
    await pumpAppointment(tester);

    await tester.tap(find.text('12:30'));
    await tester.pump();
    await tester.tap(find.text('Создать запись'));
    await tester.pump();

    expect(
      find.textContaining('Приём перенесён на 20.07, 12:30'),
      findsOneWidget,
    );
  });

  group('предоплата записи', () {
    testWidgets('подписчику Gold показывает цену со скидкой и без кнопки', (
      tester,
    ) async {
      // FakeProfileRepository отдаёт Gold-профиль по умолчанию.
      await pumpAppointment(tester);

      expect(find.text('Предоплата записи'), findsOneWidget);
      expect(find.text('10 000 ₸'), findsOneWidget);
      expect(find.text('15 000 ₸'), findsOneWidget);
      expect(find.text('Цена с подпиской Gold'), findsOneWidget);
      expect(find.text('Оплата через Kaspi.kz'), findsOneWidget);
      expect(find.text('Оплата через Apple Pay'), findsOneWidget);
      expect(find.text('Оформить подписку'), findsNothing);
    });

    testWidgets('без подписки показывает полную цену и кнопку подписки', (
      tester,
    ) async {
      final freeProfile = UserProfile(
        id: 'u1',
        firstName: 'Имя',
        lastName: 'Фамилия',
        gender: Gender.male,
        birthDate: DateTime(1996, 12, 6),
        subscription: SubscriptionTier.free,
      );

      await pumpAppointment(tester, profile: freeProfile);

      expect(find.text('Цена с подпиской Gold'), findsNothing);
      expect(
        find.text('или оформите подписку и получите скидку'),
        findsOneWidget,
      );
      expect(find.text('Оформить подписку'), findsOneWidget);
      // Полная цена стоит и крупно сверху, и зачёркнутой рядом со скидкой.
      expect(find.text('15 000 ₸'), findsNWidgets(2));
      expect(find.text('10 000 ₸'), findsOneWidget);
    });
  });
}
