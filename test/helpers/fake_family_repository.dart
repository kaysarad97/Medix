import 'package:medix/features/family_access/data/repositories/family_repository.dart';
import 'package:medix/features/family_access/domain/entities/family_member_draft.dart';
import 'package:medix/shared/models/analysis_result.dart';
import 'package:medix/shared/models/family_member.dart';
import 'package:medix/shared/models/my_doctor.dart';

/// Те же данные, что у [MockFamilyRepository], но без задержки: таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
///
/// Правки запоминаются в [added], [updated] и [removed] — форме члена семьи
/// проверять нечего, кроме того, что она дошла до репозитория с нужными
/// значениями.
class FakeFamilyRepository implements FamilyRepository {
  FakeFamilyRepository();

  final List<FamilyMemberDraft> added = [];
  final List<(String, FamilyMemberDraft)> updated = [];
  final List<String> removed = [];

  final List<FamilyMember> _members = [...MockFamilyRepository.mockMembers];

  @override
  Future<List<FamilyMember>> members() async => List.unmodifiable(_members);

  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async =>
      MockFamilyRepository.mockDoctors[memberId] ?? const [];

  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async =>
      MockFamilyRepository.mockAnalyses[memberId] ?? const [];

  @override
  Future<FamilyMember> add(FamilyMemberDraft draft) async {
    added.add(draft);
    final member = FamilyMember(
      id: 'f${_members.length + 1}',
      firstName: draft.fullName,
      lastName: '',
      birthDate: draft.birthDate,
      relation: FamilyRelation.child,
      relationshipLabel: draft.relation,
    );
    _members.add(member);
    return member;
  }

  @override
  Future<FamilyMember> update(String id, FamilyMemberDraft draft) async {
    updated.add((id, draft));
    final index = _members.indexWhere((member) => member.id == id);
    final old = _members[index];
    _members[index] = FamilyMember(
      id: id,
      firstName: draft.fullName,
      lastName: '',
      birthDate: draft.birthDate,
      relation: old.relation,
      relationshipLabel: draft.relation,
    );
    return _members[index];
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    _members.removeWhere((member) => member.id == id);
  }
}
