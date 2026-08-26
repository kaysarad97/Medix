/// Короткоживущая presigned-форма для загрузки аватара члена семьи.
class FamilyAvatarUploadTicket {
  const FamilyAvatarUploadTicket({
    required this.uploadUrl,
    required this.fields,
    required this.key,
    required this.expiresAt,
  });

  final String uploadUrl;
  final Map<String, String> fields;
  final String key;
  final DateTime expiresAt;
}
