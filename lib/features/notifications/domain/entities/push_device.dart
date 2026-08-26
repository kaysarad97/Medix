class PushDevice {
  const PushDevice({
    required this.id,
    required this.platform,
    required this.createdAt,
    required this.lastSeenAt,
  });

  final String id;
  final String platform;
  final DateTime createdAt;
  final DateTime lastSeenAt;
}
