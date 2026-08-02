import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/medical_card.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> profile();

  Future<MedicalCard> medicalCard();

  Future<List<MyDoctor>> myDoctors();

  Future<List<AnalysisResult>> analyses();

  Future<void> saveMedicalCard(MedicalCard card);
}

/// Заглушка на время разработки бэкенда. Данные — с макетов
/// `design/Профиль.png` и `design/Медкарта.png`.
class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  static const Duration _latency = Duration(milliseconds: 300);

  @override
  Future<UserProfile> profile() async {
    await Future<void>.delayed(_latency);
    return mockProfile;
  }

  @override
  Future<MedicalCard> medicalCard() async {
    await Future<void>.delayed(_latency);
    return const MedicalCard(
      bloodGroup: BloodGroup.first,
      rhesus: RhesusFactor.positive,
      hasChronicDiseases: true,
      heightCm: 176,
      weightKg: 77,
      hasBadHabits: true,
    );
  }

  @override
  Future<List<MyDoctor>> myDoctors() async {
    await Future<void>.delayed(_latency);
    return mockDoctors;
  }

  @override
  Future<List<AnalysisResult>> analyses() async {
    await Future<void>.delayed(_latency);
    return mockAnalyses;
  }

  @override
  Future<void> saveMedicalCard(MedicalCard card) async {
    // Сохранять некуда: бэкенда нет, а хранить мед-данные в открытом виде
    // на устройстве нельзя — закон РК «О персональных данных».
    await Future<void>.delayed(_latency);
  }

  static final UserProfile mockProfile = UserProfile(
    id: 'u1',
    firstName: 'Имя',
    lastName: 'Фамилия',
    gender: Gender.male,
    birthDate: DateTime(1996, 12, 6),
    subscription: SubscriptionTier.gold,
    email: 'user@medix.kz',
    heightCm: 176,
    weightKg: 77,
    avatarAsset: MedixAvatars.fallback,
  );

  static const List<MyDoctor> mockDoctors = [
    MyDoctor(id: 'd2', specialty: 'Офтальмолог', fullName: 'Ф. Имя Отчество'),
    MyDoctor(id: 'd1', specialty: 'Терапевт', fullName: 'Ф. Имя Отчество'),
    MyDoctor(id: 'd3', specialty: 'Кардиолог', fullName: 'Ф. Имя Отчество'),
  ];

  /// В макете все четыре строки одинаковые — это заглушка дизайнера.
  /// Значения оставлены как есть, чтобы вёрстка сверялась один в один.
  static final List<AnalysisResult> mockAnalyses = [
    for (var i = 0; i < 4; i++)
      AnalysisResult(
        id: 'a$i',
        name: 'Железо\nв сыворотке',
        value: 24.8,
        unit: 'мкмоль/л',
        referenceLow: 10.7,
        referenceHigh: 32.2,
        takenAt: DateTime(2026, 7, 20 - i),
      ),
  ];
}
