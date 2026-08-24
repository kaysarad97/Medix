/// Строка в списке «Все чаты».
class ChatThread {
  const ChatThread({
    required this.id,
    required this.doctorName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastMessageIsMine,
    this.isRead = true,
    this.doctorId,
    this.doctorPhotoUrl,
  });

  final String id;
  final String doctorName;
  final String lastMessage;
  final DateTime lastMessageAt;

  /// Своя реплика показывается с приставкой «Вы: ».
  final bool lastMessageIsMine;

  /// Непрочитанная строка в макете подсвечена голубым.
  final bool isRead;

  final String? doctorId;
  final String? doctorPhotoUrl;

  /// «21.07, 13:44».
  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(lastMessageAt.day)}.${two(lastMessageAt.month)}, '
        '${two(lastMessageAt.hour)}:${two(lastMessageAt.minute)}';
  }
}

/// Реплика в переписке с врачом.
class DoctorMessage {
  const DoctorMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime sentAt;
}
