import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/profile/presentation/providers/profile_providers.dart';
import 'package:medix/shared/models/app_language.dart';
import 'package:medix/shared/providers/app_settings_provider.dart';
import 'package:medix/shared/services/preferences_service.dart';

void main() {
  ProviderContainer containerWith(PreferencesService preferences) {
    final container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('Язык интерфейса', () {
    test('читается из хранилища при запуске', () {
      final container = containerWith(InMemoryPreferences(language: 'kk'));

      expect(container.read(appSettingsProvider).language, AppLanguage.kk);
    });

    test('выбор уходит в хранилище', () async {
      final preferences = InMemoryPreferences();
      final container = containerWith(preferences);

      await container
          .read(appSettingsProvider.notifier)
          .selectLanguage(AppLanguage.en);

      expect(preferences.readLanguage(), 'en');
    });

    test('без сохранённого значения остаётся русский', () {
      final container = containerWith(InMemoryPreferences());

      expect(container.read(appSettingsProvider).language, AppLanguage.ru);
    });

    test('чужой код в хранилище не роняет запуск', () {
      // Такое возможно после отката версии, где список языков был другим.
      final container = containerWith(InMemoryPreferences(language: 'zz'));

      expect(container.read(appSettingsProvider).language, AppLanguage.ru);
    });
  });

  group('Выбранная аватарка', () {
    test('читается из хранилища при запуске', () {
      final container = containerWith(
        InMemoryPreferences(avatar: 'assets/images/avatars/avatar_07.png'),
      );

      expect(
        container.read(avatarSelectionProvider),
        'assets/images/avatars/avatar_07.png',
      );
    });

    test('выбор уходит в хранилище', () async {
      final preferences = InMemoryPreferences();
      final container = containerWith(preferences);

      await container
          .read(avatarSelectionProvider.notifier)
          .select('assets/images/avatars/avatar_03.png');

      expect(preferences.readAvatar(), 'assets/images/avatars/avatar_03.png');
    });
  });
}
