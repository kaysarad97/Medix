import '../../l10n/app_localizations.dart';
import '../../shared/models/family_member.dart';

/// Подписи степеней родства.
///
/// Не в самом [FamilyRelation]: перечисление лежит в `shared/models`, а
/// модели ничего не знают о `BuildContext` и `AppLocalizations`.
///
/// Значений у родства пять, а макетов карточки два — детский и взрослый.
/// Поэтому подписи собраны в три набора: ребёнок, родитель и все остальные
/// («близкий»). Если дизайнер нарисует свои экраны для супруга и брата,
/// расходиться придётся только здесь.
extension FamilyRelationLabels on FamilyRelation {
  /// «Ребёнок», «Родитель» — поле «Родство с Вами» и выбор в форме.
  String name(AppLocalizations l10n) => switch (this) {
    FamilyRelation.spouse => l10n.familyRelationSpouse,
    FamilyRelation.child => l10n.familyRelationChild,
    FamilyRelation.parent => l10n.familyRelationParent,
    FamilyRelation.sibling => l10n.familyRelationSibling,
    FamilyRelation.other => l10n.familyRelationOther,
  };

  /// Заголовок верхней строки на карточке члена семьи.
  String screenTitle(AppLocalizations l10n) => switch (this) {
    FamilyRelation.child => l10n.familyMemberTitleChild,
    FamilyRelation.parent => l10n.familyMemberTitleSenior,
    _ => l10n.familyMemberTitleRelative,
  };

  /// Подпись под именем в плитке «Моя Семья».
  String roleLabel(AppLocalizations l10n) => switch (this) {
    FamilyRelation.child => l10n.familyRoleChild,
    FamilyRelation.parent => l10n.familyRoleSenior,
    _ => l10n.familyRoleRelative,
  };

  /// Заголовок входа в чужой профиль на «Ваша Мед-Карта» — вместо имени.
  String entryLabel(AppLocalizations l10n) => switch (this) {
    FamilyRelation.child => l10n.familyProfileChild,
    FamilyRelation.parent => l10n.familyProfileSenior,
    _ => l10n.familyProfileRelative,
  };

  /// Заголовок карточки «Врачи…» на карточке члена семьи.
  String doctorsCardTitle(AppLocalizations l10n) => switch (this) {
    FamilyRelation.child => l10n.familyDoctorsCardTitleChild,
    FamilyRelation.parent => l10n.familyDoctorsCardTitleSenior,
    _ => l10n.familyDoctorsCardTitleRelative,
  };
}
