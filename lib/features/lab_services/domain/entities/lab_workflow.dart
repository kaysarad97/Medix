class ReferralUploadTicket {
  const ReferralUploadTicket({
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

enum LabReferralStatus { pending, processing, completed, failed, unknown }

class LabReferral {
  const LabReferral({
    required this.id,
    required this.status,
    required this.recognizedTests,
    required this.createdAt,
    this.familyMemberId,
    this.failureReason,
  });

  final String id;
  final String? familyMemberId;
  final LabReferralStatus status;
  final List<Map<String, dynamic>> recognizedTests;
  final String? failureReason;
  final DateTime createdAt;
}

class LabPriceOffer {
  const LabPriceOffer({
    required this.labId,
    required this.labName,
    required this.totalPrice,
    required this.priceForUser,
    required this.discountPercent,
    this.discountReason,
    this.pricesUpdatedAt,
  });

  final String labId;
  final String labName;
  final int totalPrice;
  final int priceForUser;
  final int discountPercent;
  final String? discountReason;
  final DateTime? pricesUpdatedAt;
}

class LabOrder {
  const LabOrder({
    required this.id,
    required this.referralId,
    required this.labId,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String referralId;
  final String labId;
  final int totalPrice;
  final String status;
  final DateTime createdAt;
}

class LabResultFile {
  const LabResultFile({
    required this.id,
    required this.labOrderId,
    required this.createdAt,
  });

  final String id;
  final String labOrderId;
  final DateTime createdAt;
}

class LabResultDownload {
  const LabResultDownload({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
