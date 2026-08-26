import '../../../../core/utils/ru_dates.dart';

/// Строка списка «Все чаты» со стороны врача — `Чаты с пациентами.png`.
///
/// Не переиспользует `ChatThread` из фичи `chats`: там собеседник — врач
/// (`doctorName`), здесь наоборот, пациент, и хранить имя пациента в поле с
/// названием `doctorName` — верный способ запутать следующего читателя.
/// Remote-репозиторий наполняет эту UI-модель из `/consultations/*`; отдельная
/// сущность сохраняется, потому что здесь собеседник — пациент.
class PatientChatThread {
  const PatientChatThread({
    required this.id,
    required this.patientName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageIsMine,
    this.isRead = true,
    this.patientAvatarAsset,
  });

  final String id;
  final String patientName;
  final String lastMessage;
  final DateTime lastMessageAt;

  /// Своя реплика показывается с приставкой «Вы: ».
  final bool lastMessageIsMine;

  /// Непрочитанная строка в макете подсвечена голубым.
  final bool isRead;

  final String? patientAvatarAsset;

  /// «21.07, 13:44».
  String get timeLabel =>
      '${RuDates.dayMonth(lastMessageAt)}, '
      '${RuDates.hourMinute(lastMessageAt)}';
}

/// Реплика в переписке с пациентом.
class PatientMessage {
  const PatientMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  final String id;
  final String text;

  /// Своё — то, что написал врач: справа и синим.
  final bool isMine;

  final DateTime sentAt;
}
