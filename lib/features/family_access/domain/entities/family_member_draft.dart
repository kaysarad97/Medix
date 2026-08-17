import '../../../../shared/models/family_member.dart';

/// Что пользователь ввёл в форме члена семьи.
///
/// Поля макета — ФИО, дата рождения и родство. Сервер принимает ещё пол и
/// ИИН, но обоих в макете формы нет, и заполнить их пока неоткуда: пол в
/// карточке остаётся прочерком, пока дизайнер не ответит, спрашивать ли его.
///
/// ФИО одной строкой, как на шаге регистрации: сервер тоже хранит его одним
/// полем, а разбивка на имя и фамилию нужна только карточке.
class FamilyMemberDraft {
  const FamilyMemberDraft({
    required this.fullName,
    required this.birthDate,
    required this.relation,
  });

  final String fullName;
  final DateTime birthDate;

  /// Одно из пяти значений сервера, а не свободный текст: с 17 августа
  /// 2026 `relation` — перечисление.
  final FamilyRelation relation;
}
