import 'package:medix/features/family_access/data/repositories/family_repository.dart';
import 'package:medix/shared/models/analysis_result.dart';
import 'package:medix/shared/models/family_member.dart';
import 'package:medix/shared/models/my_doctor.dart';

/// Те же данные, что у [MockFamilyRepository], но без задержки: таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeFamilyRepository implements FamilyRepository {
  const FakeFamilyRepository();

  @override
  Future<List<FamilyMember>> members() async =>
      MockFamilyRepository.mockMembers;

  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async =>
      MockFamilyRepository.mockDoctors[memberId] ?? const [];

  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async =>
      MockFamilyRepository.mockAnalyses[memberId] ?? const [];
}
