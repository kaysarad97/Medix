/// Специальность врача — карусель «Врачи» на главной и грид «Все Врачи»
/// на экране поиска врача.
class DoctorSpecialty {
  const DoctorSpecialty({
    required this.id,
    required this.title,
    required this.doctorCount,
    this.photoUrl,
  });

  final String id;
  final String title;
  final int doctorCount;

  /// Фотография врача-представителя. Приходит с бэкенда; пока пусто.
  final String? photoUrl;
}
