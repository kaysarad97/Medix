import 'package:medix/features/profile/data/repositories/profile_repository.dart';
import 'package:medix/features/profile/domain/entities/medical_card.dart';
import 'package:medix/features/profile/domain/entities/medical_procedure.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';
import 'package:medix/shared/models/analysis_result.dart';
import 'package:medix/shared/models/my_doctor.dart';
import 'package:medix/shared/models/subscription_tier.dart';

/// Те же данные, что у [MockProfileRepository], но без задержки: таймер вне
/// `runAsync` роняет виджет-тест на «timersPending».
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({this.subscription});

  /// Чем подменить тариф из мока. Нужен экранам, где что-то доступно
  /// только по Gold: у мок-профиля он как раз Gold, и бесплатную ветку
  /// иначе не проверить.
  final SubscriptionTier? subscription;

  @override
  Future<UserProfile> profile() async {
    final profile = MockProfileRepository.mockProfile;
    if (subscription == null) return profile;
    return UserProfile(
      id: profile.id,
      firstName: profile.firstName,
      lastName: profile.lastName,
      gender: profile.gender,
      birthDate: profile.birthDate,
      subscription: subscription!,
      email: profile.email,
      registrationAddress: profile.registrationAddress,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      avatarAsset: profile.avatarAsset,
      avatarUrl: profile.avatarUrl,
    );
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async => profile;

  @override
  Future<AvatarUploadTicket> requestAvatarUpload({
    required String filename,
    required String contentType,
  }) async => AvatarUploadTicket(
    uploadUrl: 'https://storage.example/avatar',
    fields: const {},
    key: 'avatars/u1/$filename',
    expiresAt: DateTime(2026, 8, 21, 12),
  );

  @override
  Future<UserProfile> confirmAvatar(String s3Key) => profile();

  /// Сохранённая карта. Заглушка не выбрасывает записанное, как раньше:
  /// иначе не поймать, что экран не перечитал карту после сохранения.
  MedicalCard? _saved;

  @override
  // Ответы «да» — как в макете `Медкарта.png`, где обе кнопки залиты.
  Future<MedicalCard> medicalCard() async =>
      _saved ??
      const MedicalCard(
        bloodGroup: BloodGroup.first,
        rhesus: RhesusFactor.positive,
        hasChronicDiseases: true,
        hasBadHabits: true,
        heightCm: 176,
        weightKg: 77,
      );

  @override
  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  }) async => const [];

  @override
  Future<List<MyDoctor>> myDoctors() async => MockProfileRepository.mockDoctors;

  @override
  Future<List<AnalysisResult>> analyses() async =>
      MockProfileRepository.mockAnalyses;

  @override
  Future<List<MedicalProcedure>> procedures() async =>
      MockProfileRepository.mockProcedures;

  @override
  Future<void> saveMedicalCard(MedicalCard card) async => _saved = card;
}
