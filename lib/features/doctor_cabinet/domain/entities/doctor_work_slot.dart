enum DoctorWorkSlotStatus { open, held, booked, cancelled, unknown }

/// Рабочий интервал из `/doctors/me/schedule`.
class DoctorWorkSlot {
  const DoctorWorkSlot({
    required this.id,
    required this.doctorId,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  final String id;
  final String doctorId;
  final DateTime startsAt;
  final DateTime endsAt;
  final DoctorWorkSlotStatus status;
}

/// Новый свободный интервал, отправляемый в `/doctors/me/slots`.
class DoctorWorkSlotDraft {
  const DoctorWorkSlotDraft({required this.startsAt, required this.endsAt});

  final DateTime startsAt;
  final DateTime endsAt;
}
