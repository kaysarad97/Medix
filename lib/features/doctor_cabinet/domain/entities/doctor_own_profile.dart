/// Собственный профиль врача — «Ваш Профиль» в кабинете врача.
///
/// Не связан с пациентским `Doctor` (телемедицина): та сущность — карточка
/// врача, которую листает пациент при поиске, эта — данные врача о себе.
class DoctorOwnProfile {
  const DoctorOwnProfile({
    required this.fullName,
    required this.doctorId,
    required this.status,
    required this.rating,
    required this.specialization,
    required this.experience,
    required this.category,
    required this.address,
    required this.onlineConsultations,
    required this.phone,
    required this.email,
  });

  final String fullName;

  /// «11233МК» — идентификатор врача в системе.
  final String doctorId;

  /// «активен» — статус аккаунта, в макете простой текст, не индикатор.
  final String status;

  final double rating;

  final String specialization;
  final String experience;
  final String category;
  final String address;

  /// `true` — подсвечен «Онлайн-прием», `false` — «Оффлайн-прием». В
  /// макете это не переключатель с двумя активными состояниями сразу, а
  /// одно из двух — выбор одной заливкой.
  final bool onlineConsultations;

  final String phone;
  final String email;

  String get ratingLabel => rating.toStringAsFixed(1);
}
