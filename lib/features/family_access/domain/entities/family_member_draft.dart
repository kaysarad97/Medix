/// Что пользователь ввёл в форме члена семьи.
///
/// Ровно те три поля, которые принимает бэкенд: `full_name`, `birth_date`,
/// `relation`. Пол, рост и вес сюда не входят намеренно — сервер их не
/// хранит, и спрашивать их, чтобы тут же потерять, нельзя.
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

  /// «Сын», «Мама» — свободный текст, словаря на сервере нет.
  final String relation;
}
