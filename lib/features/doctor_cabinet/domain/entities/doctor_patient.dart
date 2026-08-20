import '../../../../shared/models/analysis_result.dart';
import 'doctor_appointment.dart';

/// Пациент глазами врача — «Профиль пациента.png» и
/// «Запись с пациентом.png».
///
/// Не переиспользует пациентский `UserProfile`: там аккаунт со своей
/// подпиской, почтой и настройками, а здесь врач видит ровно то, что нужно
/// на приёме — рост, вес, возраст, ближайшую запись, заключение и анализы.
/// Общее у обеих сущностей — только [AnalysisResult], он и так лежит в
/// `shared/`.
class DoctorPatient {
  const DoctorPatient({
    required this.id,
    required this.fullName,
    required this.heightCm,
    required this.weightKg,
    required this.age,
    this.avatarAsset,
    this.appointment,
    this.conclusion,
    this.analyses = const [],
  });

  final String id;
  final String fullName;
  final int heightCm;
  final int weightKg;
  final int age;
  final String? avatarAsset;

  /// Запись, о которой идёт речь: на «Профиле пациента» её подтверждают, на
  /// «Записи с пациентом» по ней звонят. `null` — записи нет, и обе
  /// карточки не рисуются.
  final DoctorAppointment? appointment;

  /// Заключение врача. `null` — ещё не загружено, и на его месте стоит
  /// объяснение из макета.
  final String? conclusion;

  final List<AnalysisResult> analyses;

  /// «170 см» — единицы как в пациентском профиле, тем же огрублением.
  String get heightLabel => '$heightCm см';

  String get weightLabel => '$weightKg кг';

  /// «30 лет». Склонения нет — как и везде в приложении.
  String get ageLabel => '$age лет';
}
