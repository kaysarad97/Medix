/// Специальность в карусели «Врачи» на главной.
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
