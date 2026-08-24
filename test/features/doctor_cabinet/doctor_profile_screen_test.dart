import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_profile_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool showAdminRequests = true,
    FakeDoctorCabinetRepository repository =
        const FakeDoctorCabinetRepository(),
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DoctorOwnProfileScreen(showAdminRequests: showAdminRequests),
        ),
      ),
    );
  }

  testWidgets('рисует шапку, данные врача и ссылки', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ваш Профиль'), findsOneWidget);
    expect(find.text('Имя Фамилия'), findsOneWidget);
    expect(find.text('11233МК'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Ваша Информация'), findsOneWidget);
    expect(find.text('+7 700 000 0000'), findsOneWidget);
    expect(find.text('abcefg@mail.com'), findsOneWidget);
    expect(find.text('Ваши сертификаты'), findsOneWidget);
    expect(find.text('Отзывы о Вас'), findsOneWidget);
    expect(find.text('Запросы в администрацию'), findsOneWidget);
  });

  testWidgets('без showAdminRequests строка администрации не рисуется', (
    tester,
  ) async {
    await pumpScreen(tester, showAdminRequests: false);
    await tester.pump();
    await tester.pump();

    expect(find.text('Запросы в администрацию'), findsNothing);
  });

  testWidgets('показывает фотографию из профиля врача', (tester) async {
    await pumpScreen(
      tester,
      repository: const FakeDoctorCabinetRepository(
        photoUrl: 'https://cdn.example/doctor.jpg',
      ),
    );
    await tester.pump();
    await tester.pump();

    final image = tester.widget<Image>(
      find.byKey(const Key('doctor-profile-photo')),
    );
    expect((image.image as NetworkImage).url, 'https://cdn.example/doctor.jpg');
  });
}
