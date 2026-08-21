import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище пользовательских предпочтений: язык интерфейса и выбранная
/// аватарка.
///
/// Отдельно от [SecureStorageService] намеренно. Там лежат токены — секреты,
/// ради которых приложение ходит в Keychain и шифрует запись. Язык интерфейса
/// секретом не является, а чтение из Keychain медленнее: язык нужен ещё до
/// первого кадра, иначе интерфейс мигнёт русским и переключится на глазах.
///
/// Чтение синхронное — ради того же первого кадра. Экземпляр создаётся один
/// раз в `main`, до `runApp`.
abstract interface class PreferencesService {
  /// Код языка из [AppLanguage] или `null`, если пользователь не выбирал.
  String? readLanguage();

  Future<void> saveLanguage(String code);

  /// Путь к картинке из `MedixAvatars` или `null`.
  String? readAvatar();

  Future<void> saveAvatar(String asset);

  Future<void> clearAvatar();
}

class SharedPreferencesService implements PreferencesService {
  const SharedPreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const _languageKey = 'medix.language';
  static const _avatarKey = 'medix.avatar';

  @override
  String? readLanguage() => _prefs.getString(_languageKey);

  @override
  Future<void> saveLanguage(String code) =>
      _prefs.setString(_languageKey, code);

  @override
  String? readAvatar() => _prefs.getString(_avatarKey);

  @override
  Future<void> saveAvatar(String asset) => _prefs.setString(_avatarKey, asset);

  @override
  Future<void> clearAvatar() => _prefs.remove(_avatarKey);
}

/// Память вместо диска.
///
/// Стоит по умолчанию, чтобы виджет-тесты работали без плагина и без
/// подмены в каждом `ProviderScope`: настоящее хранилище подставляется
/// в `main`. Заодно на нём проверяется, что выбор вообще сохраняется.
class InMemoryPreferences implements PreferencesService {
  InMemoryPreferences({String? language, String? avatar})
    : _language = language,
      _avatar = avatar;

  String? _language;
  String? _avatar;

  @override
  String? readLanguage() => _language;

  @override
  Future<void> saveLanguage(String code) async => _language = code;

  @override
  String? readAvatar() => _avatar;

  @override
  Future<void> saveAvatar(String asset) async => _avatar = asset;

  @override
  Future<void> clearAvatar() async => _avatar = null;
}

/// Подменяется в `main` на [SharedPreferencesService] — там уже есть
/// готовый `SharedPreferences`, полученный до запуска приложения.
final preferencesServiceProvider = Provider<PreferencesService>(
  (ref) => InMemoryPreferences(),
);
