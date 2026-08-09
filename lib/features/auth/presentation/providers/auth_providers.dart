import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';

/// Работать против заглушки вместо реального API.
///
/// Авторизация на бэкенде готова, поэтому по умолчанию приложение ходит в
/// настоящий API. Заглушка остаётся для работы без поднятого сервера:
/// `flutter run --dart-define=MEDIX_USE_MOCKS=true`
const bool useMocks = bool.fromEnvironment('MEDIX_USE_MOCKS');

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMocks) return const MockAuthRepository();

  return RemoteAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
});
