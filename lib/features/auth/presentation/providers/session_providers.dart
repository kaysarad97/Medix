import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/secure_storage_service.dart';

/// Есть ли сохранённая сессия.
///
/// Проверяется refresh-токен, а не access: access живёт минуты и к моменту
/// запуска почти всегда просрочен, а refresh — то, по чему сессию можно
/// восстановить.
///
/// TODO(auth): когда появится бэкенд, здесь же дёргать `/auth/refresh` и
/// считать сессию живой только при успешном ответе. Сейчас достаточно факта
/// наличия токена: проверять его на сервере всё равно нечем.
final hasStoredSessionProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  final token = await storage.readRefreshToken();
  return token != null && token.isNotEmpty;
});
