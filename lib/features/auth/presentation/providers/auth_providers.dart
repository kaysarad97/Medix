import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/services/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/doctor_registration_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMocks) return const MockAuthRepository();

  return RemoteAuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

final doctorRegistrationRepositoryProvider =
    Provider<DoctorRegistrationRepository>((ref) {
      if (useMocks) return const MockDoctorRegistrationRepository();
      return RemoteDoctorRegistrationRepository(
        ref.watch(dioClientProvider),
        ref.watch(secureStorageServiceProvider),
      );
    });
