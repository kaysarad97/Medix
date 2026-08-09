import 'package:medix/features/auth/data/repositories/auth_repository.dart';
import 'package:medix/features/auth/presentation/providers/auth_providers.dart';

/// Подменяет репозиторий авторизации заглушкой.
///
/// Нужен явно в каждом тесте: по умолчанию приложение ходит в настоящий API
/// (см. `useMocks`), а тому нужен и живой сервер, и защищённое хранилище,
/// которого в тестовом окружении нет. Раньше тесты опирались на то, что
/// заглушка стоит по умолчанию, — теперь это не так.
final authOverrides = [
  authRepositoryProvider.overrideWithValue(const MockAuthRepository()),
];
