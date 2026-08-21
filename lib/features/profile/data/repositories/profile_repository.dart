import '../../../../shared/models/analysis_result.dart';
import '../../../../shared/models/gender.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../../../../shared/models/my_doctor.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/medical_card.dart';
import '../../domain/entities/medical_procedure.dart';
import '../../domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile> profile();

  Future<UserProfile> saveProfile(UserProfile profile);

  Future<AvatarUploadTicket> requestAvatarUpload({
    required String filename,
    required String contentType,
  });

  Future<UserProfile> confirmAvatar(String s3Key);

  Future<MedicalCard> medicalCard();

  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  });

  Future<List<MyDoctor>> myDoctors();

  Future<List<AnalysisResult>> analyses();

  Future<List<MedicalProcedure>> procedures();

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
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await Future<void>.delayed(_latency);
    return profile;
  }

  @override
  Future<AvatarUploadTicket> requestAvatarUpload({
    required String filename,
    required String contentType,
  }) async {
    await Future<void>.delayed(_latency);
    return AvatarUploadTicket(
      uploadUrl: 'https://storage.example/avatar',
      fields: const {},
      key: 'avatars/u1/$filename',
      expiresAt: DateTime(2026, 8, 21, 12),
    );
  }

  @override
  Future<UserProfile> confirmAvatar(String s3Key) async {
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
  Future<List<MeasurementPoint>> measurementHistory(
    MeasurementKind kind, {
    String? familyMemberId,
    DateTime? from,
    DateTime? to,
  }) async {
    await Future<void>.delayed(_latency);
    final unit = kind == MeasurementKind.height ? 'cm' : 'kg';
    final value = kind == MeasurementKind.height ? 176.0 : 77.0;
    return [
      MeasurementPoint(
        id: 'measurement-${kind.apiValue}',
        kind: kind,
        value: value,
        unit: unit,
        measuredAt: DateTime(2026, 7, 20),
      ),
    ];
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
  Future<List<MedicalProcedure>> procedures() async {
    await Future<void>.delayed(_latency);
    return mockProcedures;
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
    subscription: SubscriptionTier.silver,
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

  /// `design/Предыдущие Процедуры.png` показывает один и тот же ряд
  /// специальностей (Пульмонолог, Гастроэнтеролог, ЛОР, Дерматолог) — как и
  /// с анализами выше, это заглушка дизайнера, а не данные. Мок разнообразит
  /// специальности и добавляет пару записей на вкладки «Процедуры ребёнка»/
  /// «Процедуры старших», иначе фильтр было бы не на чем проверить.
  static final List<MedicalProcedure> mockProcedures = [
    MedicalProcedure(
      id: 'p1',
      doctorName: 'Имя Фамилия',
      specialty: 'Пульмонолог',
      date: DateTime(2026, 5, 21),
    ),
    MedicalProcedure(
      id: 'p2',
      doctorName: 'Имя Фамилия',
      specialty: 'Гастроэнтеролог',
      date: DateTime(2026, 5, 20),
    ),
    MedicalProcedure(
      id: 'p3',
      doctorName: 'Имя Фамилия',
      specialty: 'ЛОР',
      date: DateTime(2026, 5, 19),
    ),
    MedicalProcedure(
      id: 'p4',
      doctorName: 'Имя Фамилия',
      specialty: 'Дерматолог',
      date: DateTime(2026, 5, 18),
    ),
    MedicalProcedure(
      id: 'p5',
      doctorName: 'Имя Фамилия',
      specialty: 'Кардиолог',
      date: DateTime(2026, 5, 17),
    ),
    MedicalProcedure(
      id: 'p6',
      doctorName: 'Имя Фамилия',
      specialty: 'Терапевт',
      date: DateTime(2026, 5, 10),
    ),
    MedicalProcedure(
      id: 'p7',
      doctorName: 'Имя Фамилия',
      specialty: 'Педиатр',
      date: DateTime(2026, 5, 21),
      scope: FamilyScope.child,
    ),
    MedicalProcedure(
      id: 'p8',
      doctorName: 'Имя Фамилия',
      specialty: 'Аллерголог',
      date: DateTime(2026, 5, 15),
      scope: FamilyScope.child,
    ),
    MedicalProcedure(
      id: 'p9',
      doctorName: 'Имя Фамилия',
      specialty: 'Офтальмолог',
      date: DateTime(2026, 5, 21),
      scope: FamilyScope.senior,
    ),
    MedicalProcedure(
      id: 'p10',
      doctorName: 'Имя Фамилия',
      specialty: 'Невролог',
      date: DateTime(2026, 5, 14),
      scope: FamilyScope.senior,
    ),
  ];
}
