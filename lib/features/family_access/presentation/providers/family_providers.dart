import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/family_member.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/services/family_avatar_upload_service.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  if (useMocks) return MockFamilyRepository();

  return RemoteFamilyRepository(ref.watch(dioClientProvider));
});

/// Загрузка фото члена семьи через тот же presigned-цикл, что и у аватара
/// пользователя (`avatar_upload_service.dart` в фиче `profile`) — endpoint'ы
/// на бэкенде уже покрыты, не хватало только точки входа в UI.
final familyAvatarUploadServiceProvider = Provider<FamilyAvatarUploadService>((
  ref,
) {
  final repository = ref.watch(familyRepositoryProvider);
  return useMocks
      ? MockFamilyAvatarUploadService(repository)
      : RemoteFamilyAvatarUploadService(repository);
});

final familyMembersProvider = FutureProvider<List<FamilyMember>>(
  (ref) => ref.watch(familyRepositoryProvider).members(),
);

/// Один член семьи по id. Сервер имеет отдельный endpoint детали, поэтому
/// глубокая ссылка не зависит от того, успел ли загрузиться общий список.
final familyMemberProvider = FutureProvider.family<FamilyMember?, String>(
  (ref, id) => ref.watch(familyRepositoryProvider).member(id),
);

final familyDoctorsProvider = FutureProvider.family<List<MyDoctor>, String>(
  (ref, id) => ref.watch(familyRepositoryProvider).doctorsOf(id),
);

final familyAnalysesProvider =
    FutureProvider.family<List<AnalysisResult>, String>(
      (ref, id) => ref.watch(familyRepositoryProvider).analysesOf(id),
    );

/// Выбранная вкладка над списком анализов члена семьи.
final familyAnalysesFilterProvider =
    NotifierProvider<FamilyAnalysesFilterNotifier, AnalysesFilter>(
      FamilyAnalysesFilterNotifier.new,
    );

class FamilyAnalysesFilterNotifier extends Notifier<AnalysesFilter> {
  @override
  AnalysesFilter build() => AnalysesFilter.all;

  void select(AnalysesFilter filter) => state = filter;
}
