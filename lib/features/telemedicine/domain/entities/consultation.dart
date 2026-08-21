enum ConsultationMode { video, audio }

enum ConsultationStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  unknown,
}

class ConsultationJoin {
  const ConsultationJoin({
    required this.roomId,
    required this.webSocketTicket,
    required this.videoToken,
    required this.videoServerUrl,
    required this.mode,
    required this.expiresAt,
  });

  final String roomId;
  final String webSocketTicket;
  final String videoToken;
  final String videoServerUrl;
  final ConsultationMode mode;
  final DateTime expiresAt;
}

class Consultation {
  const Consultation({
    required this.id,
    required this.appointmentId,
    required this.status,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String appointmentId;
  final ConsultationStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
}

class ConsultationMessage {
  const ConsultationMessage({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String consultationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
}

sealed class ConsultationSocketEvent {
  const ConsultationSocketEvent();
}

class ConsultationHistoryEvent extends ConsultationSocketEvent {
  const ConsultationHistoryEvent(this.messages);

  final List<ConsultationMessage> messages;
}

class ConsultationMessageEvent extends ConsultationSocketEvent {
  const ConsultationMessageEvent(this.message);

  final ConsultationMessage message;
}

class ConsultationSocketErrorEvent extends ConsultationSocketEvent {
  const ConsultationSocketErrorEvent(this.detail);

  final String detail;
}
