import 'package:medix/features/profile/data/repositories/profile_repository.dart';
import 'package:medix/features/profile/domain/entities/analysis_result.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';

/// Те же данные, что у [MockProfileRepository], но без задержки: таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeProfileRepository implements ProfileRepository {
  const FakeProfileRepository();

  @override
  Future<UserProfile> profile() async => MockProfileRepository.mockProfile;

  @override
  // Ответы «да» — как в макете `Медкарта.png`, где обе кнопки залиты.
  Future<MedicalCard> medicalCard() async => const MedicalCard(
    bloodGroup: BloodGroup.first,
    rhesus: RhesusFactor.positive,
    hasChronicDiseases: true,
    hasBadHabits: true,
    heightCm: 176,
    weightKg: 77,
  );

  @override
  Future<List<MyDoctor>> myDoctors() async => MockProfileRepository.mockDoctors;

  @override
  Future<List<AnalysisResult>> analyses() async =>
      MockProfileRepository.mockAnalyses;

  @override
  Future<void> saveMedicalCard(MedicalCard card) async {}
}
