/// Группа крови по системе AB0. Подписи — как в макете `Медкарта.png`.
enum BloodGroup {
  first('I (O)'),
  second('II(A)'),
  third('III (B)'),
  fourth('IV(AB)');

  const BloodGroup(this.label);

  final String label;
}

enum RhesusFactor {
  positive('Rh+'),
  negative('Rh-');

  const RhesusFactor(this.label);

  final String label;
}

/// Мед-карта: то, что пользователь заполняет о себе один раз.
///
/// Все поля необязательные: карта заводится пустой и дозаполняется. Пустое
/// поле в макете показано прочерком, а не скрыто.
class MedicalCard {
  const MedicalCard({
    this.bloodGroup,
    this.rhesus,
    this.hasChronicDiseases,
    this.chronicDiseases,
    this.heightCm,
    this.weightKg,
    this.allergies,
    this.surgeries,
    this.hasBadHabits,
  });

  final BloodGroup? bloodGroup;
  final RhesusFactor? rhesus;

  /// Ответ на «Хронические заболевания: да / нет». `null` — не отвечал.
  final bool? hasChronicDiseases;

  /// Расшифровка, если ответ «да».
  final String? chronicDiseases;

  final int? heightCm;
  final int? weightKg;

  /// «Аллергии (пищевые, лекарственные, прочие)».
  final String? allergies;

  final String? surgeries;

  /// «Вредные привычки (курение, алкоголь)».
  final bool? hasBadHabits;

  MedicalCard copyWith({
    BloodGroup? bloodGroup,
    RhesusFactor? rhesus,
    bool? hasChronicDiseases,
    String? chronicDiseases,
    int? heightCm,
    int? weightKg,
    String? allergies,
    String? surgeries,
    bool? hasBadHabits,
  }) {
    return MedicalCard(
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhesus: rhesus ?? this.rhesus,
      hasChronicDiseases: hasChronicDiseases ?? this.hasChronicDiseases,
      chronicDiseases: chronicDiseases ?? this.chronicDiseases,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      allergies: allergies ?? this.allergies,
      surgeries: surgeries ?? this.surgeries,
      hasBadHabits: hasBadHabits ?? this.hasBadHabits,
    );
  }
}
