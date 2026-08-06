import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/family_member.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../../../shared/models/my_doctor.dart';

abstract interface class FamilyRepository {
  Future<List<FamilyMember>> members();

  Future<List<MyDoctor>> doctorsOf(String memberId);

  Future<List<AnalysisResult>> analysesOf(String memberId);
}

/// Заглушка на время разработки бэкенда. Данные — с макетов
/// `design/Моя Семья Ребенок.png` и `design/Моя Семья Старшие.png`.
///
/// В обоих макетах карточки врачей и строки анализов совпадают дословно с
/// теми же блоками на `design/Профиль.png` — это повторяющийся
/// Figma-плейсхолдер, не разные данные. Мок здесь намеренно свой:
/// специальности и анализы подобраны по смыслу (педиатр ребёнку, кардиолог
/// старшим), а не скопированы один в один.
class MockFamilyRepository implements FamilyRepository {
  const MockFamilyRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<List<FamilyMember>> members() async {
    await Future<void>.delayed(_latency);
    return mockMembers;
  }

  @override
  Future<List<MyDoctor>> doctorsOf(String memberId) async {
    await Future<void>.delayed(_latency);
    return mockDoctors[memberId] ?? const [];
  }

  @override
  Future<List<AnalysisResult>> analysesOf(String memberId) async {
    await Future<void>.delayed(_latency);
    return mockAnalyses[memberId] ?? const [];
  }

  static final List<FamilyMember> mockMembers = [
    FamilyMember(
      id: 'f1',
      firstName: 'Имя',
      lastName: 'Фамилия',
      gender: Gender.male,
      birthDate: DateTime(2020, 10, 7),
      relation: FamilyRelation.child,
      heightCm: 106,
      weightKg: 30,
      avatarAsset: MedixAvatars.all[5],
    ),
    FamilyMember(
      id: 'f2',
      firstName: 'Имя',
      lastName: 'Фамилия',
      gender: Gender.female,
      birthDate: DateTime(1957, 12, 9),
      relation: FamilyRelation.senior,
      heightCm: 168,
      weightKg: 64,
      avatarAsset: MedixAvatars.all[1],
    ),
  ];

  static const Map<String, List<MyDoctor>> mockDoctors = {
    'f1': [
      MyDoctor(id: 'd3', specialty: 'Педиатр', fullName: 'Ф. Имя Отчество'),
      MyDoctor(id: 'd2', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    ],
    'f2': [
      MyDoctor(id: 'd4', specialty: 'Кардиолог', fullName: 'Ф. Имя Отчество'),
      MyDoctor(id: 'd2', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    ],
  };

  static final Map<String, List<AnalysisResult>> mockAnalyses = {
    'f1': [
      AnalysisResult(
        id: 'af1-1',
        name: 'Гемоглобин',
        value: 128,
        unit: 'г/л',
        referenceLow: 110,
        referenceHigh: 140,
        takenAt: DateTime(2026, 6, 12),
      ),
      AnalysisResult(
        id: 'af1-2',
        name: 'Глюкоза',
        value: 4.6,
        unit: 'ммоль/л',
        referenceLow: 3.3,
        referenceHigh: 5.5,
        takenAt: DateTime(2026, 6, 12),
      ),
    ],
    'f2': [
      AnalysisResult(
        id: 'af2-1',
        name: 'Холестерин общий',
        value: 5.8,
        unit: 'ммоль/л',
        referenceLow: 3.0,
        referenceHigh: 5.2,
        takenAt: DateTime(2026, 5, 28),
      ),
      AnalysisResult(
        id: 'af2-2',
        name: 'Витамин D',
        value: 24,
        unit: 'нг/мл',
        referenceLow: 30,
        referenceHigh: 100,
        takenAt: DateTime(2026, 5, 28),
      ),
    ],
  };
}
