import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_language.dart';
import '../services/preferences_service.dart';

/// Настройки приложения, которые правятся на экране «Настройки» —
/// пациентском и врачебном, оба ведут в один провайдер.
///
/// Живут в памяти: экран регистрации собирает их в свой контроллер, а
/// общего хранилища настроек пока нет — появится вместе с бэкендом.
class AppSettings {
  const AppSettings({this.notificationsEnabled = true, this.language});

  final bool notificationsEnabled;

  /// Выбранный язык интерфейса. Системный не подхватываем: русский —
  /// язык по умолчанию для казахстанского рынка, см. [MedixApp].
  final AppLanguage? language;

  AppSettings copyWith({bool? notificationsEnabled, AppLanguage? language}) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
    );
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final stored = ref.read(preferencesServiceProvider).readLanguage();
    return AppSettings(language: AppLanguage.byCode(stored) ?? AppLanguage.ru);
  }

  void toggleNotifications(bool enabled) =>
      state = state.copyWith(notificationsEnabled: enabled);

  /// Экран не ждёт записи: интерфейс переключается сразу, на диск значение
  /// уходит следом. Не дойдёт — потеряется ровно один выбор, а не сессия.
  Future<void> selectLanguage(AppLanguage language) async {
    state = state.copyWith(language: language);
    await ref.read(preferencesServiceProvider).saveLanguage(language.code);
  }
}
