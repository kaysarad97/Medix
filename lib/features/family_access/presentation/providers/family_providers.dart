import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/family_member.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../data/repositories/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  // Бэкенда пока нет; переключение появится вместе с реальными эндпоинтами,
  // как в authRepositoryProvider.
  (ref) => const MockFamilyRepository(),
);

final familyMembersProvider = FutureProvider<List<FamilyMember>>(
  (ref) => ref.watch(familyRepositoryProvider).members(),
);

/// Один член семьи по id — переключатель на экране профиля ведёт сюда по
/// ссылке, поэтому подгружать нужно только выбранного, а не весь список.
final familyMemberProvider = FutureProvider.family<FamilyMember?, String>((
  ref,
  id,
) async {
  final members = await ref.watch(familyMembersProvider.future);
  for (final member in members) {
    if (member.id == id) return member;
  }
  return null;
});

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
