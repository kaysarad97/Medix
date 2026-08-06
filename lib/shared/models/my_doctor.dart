/// Врач из блока «Мои Врачи» — тот, у кого пользователь уже был.
///
/// Нужен и профилю («Мои Врачи» в мед-карте), и телемедицине («Мои Врачи»
/// на экране поиска врача) — поэтому в `shared/`, а не в одной из фич.
class MyDoctor {
  const MyDoctor({
    required this.id,
    required this.specialty,
    required this.fullName,
    this.photoUrl,
  });

  final String id;

  /// «Офтальмолог» — в макете это заголовок карточки, а не подпись.
  final String specialty;

  /// «Ф. Имя Отчество».
  final String fullName;

  final String? photoUrl;
}
