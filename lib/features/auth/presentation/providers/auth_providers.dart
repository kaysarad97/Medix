import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';

/// Работать против заглушки вместо реального API.
///
/// Бэкенд (FastAPI) ещё в разработке, поэтому по умолчанию `true`.
/// Переключается сборочным флагом:
/// `flutter run --dart-define=MEDIX_USE_MOCKS=false`
const bool useMocks = bool.fromEnvironment(
  'MEDIX_USE_MOCKS',
  defaultValue: true,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMocks) return const MockAuthRepository();

  return RemoteAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
});
