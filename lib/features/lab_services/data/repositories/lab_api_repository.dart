import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/entities/lab_workflow.dart';

class LabApiRepository {
  const LabApiRepository(this._dio);

  final Dio _dio;

  Future<ReferralUploadTicket> requestReferralUpload({
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.labReferralUploadUrl,
        data: {'filename': filename, 'content_type': contentType},
      );
      final json = response.data!;
      return ReferralUploadTicket(
        uploadUrl: json['upload_url'] as String,
        fields: (json['fields'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, value as String),
        ),
        key: json['key'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> confirmReferral({
    required String s3Key,
    String? familyMemberId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.labReferrals,
        data: {'s3_key': s3Key, 'family_member_id': familyMemberId},
      );
      return response.data!['referral_id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LabReferral> referral(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.labReferral(id),
      );
      return _referral(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LabPriceOffer>> offers(String referralId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.labOffers,
        queryParameters: {'referral_id': referralId},
      );
      return [
        for (final item in response.data ?? const [])
          _offer(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LabOrder> createOrder({
    required String referralId,
    required String labId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.labOrders,
        data: {'referral_id': referralId, 'lab_id': labId},
      );
      return _order(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LabOrder>> orders() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.labOrders);
      return [
        for (final item in response.data ?? const [])
          _order(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<LabResultFile>> results({String? familyMemberId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.labResults,
        queryParameters: {'family_member_id': ?familyMemberId},
      );
      return [
        for (final item in response.data ?? const [])
          _result(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<LabResultDownload> resultDownload(String resultId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.labResultDownloadUrl(resultId),
      );
      final json = response.data!;
      return LabResultDownload(
        url: json['download_url'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String).toLocal(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  static LabReferral _referral(Map<String, dynamic> json) => LabReferral(
    id: json['id'] as String,
    familyMemberId: json['family_member_id'] as String?,
    status: switch (json['status']) {
      'pending' => LabReferralStatus.pending,
      'processing' => LabReferralStatus.processing,
      'completed' => LabReferralStatus.completed,
      'failed' => LabReferralStatus.failed,
      _ => LabReferralStatus.unknown,
    },
    recognizedTests: [
      for (final item in json['recognized_tests'] as List<dynamic>? ?? const [])
        Map<String, dynamic>.from(item as Map),
    ],
    failureReason: json['failure_reason'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  static LabPriceOffer _offer(Map<String, dynamic> json) {
    final lab = json['lab'] as Map<String, dynamic>;
    return LabPriceOffer(
      labId: lab['id'] as String,
      labName: lab['name'] as String,
      totalPrice: (json['total_price'] as num).round(),
      priceForUser: (json['price_for_user'] as num).round(),
      discountPercent: (json['discount_percent'] as num).toInt(),
      discountReason: json['discount_reason'] as String?,
      pricesUpdatedAt: DateTime.tryParse(
        json['prices_updated_at'] as String? ?? '',
      )?.toLocal(),
    );
  }

  static LabOrder _order(Map<String, dynamic> json) => LabOrder(
    id: json['id'] as String,
    referralId: json['referral_id'] as String,
    labId: json['lab_id'] as String,
    totalPrice: (json['total_price'] as num).round(),
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );

  static LabResultFile _result(Map<String, dynamic> json) => LabResultFile(
    id: json['id'] as String,
    labOrderId: json['lab_order_id'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}
