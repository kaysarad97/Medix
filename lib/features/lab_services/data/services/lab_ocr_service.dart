import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/lab_workflow.dart';
import '../repositories/lab_api_repository.dart';
import 'referral_file_picker.dart';

abstract interface class LabOcrService {
  Future<LabReferral> uploadAndRecognize(
    PickedReferralFile file, {
    String? familyMemberId,
  });

  Future<List<LabPriceOffer>> offers(String referralId);

  Future<LabOrder> createOrder({
    required String referralId,
    required String labId,
  });
}

class RemoteLabOcrService implements LabOcrService {
  RemoteLabOcrService(
    this._repository, {
    Dio? uploadClient,
    this.pollInterval = const Duration(seconds: 2),
    this.maxPollAttempts = 30,
  }) : _uploadClient = uploadClient ?? Dio();

  final LabApiRepository _repository;
  final Dio _uploadClient;
  final Duration pollInterval;
  final int maxPollAttempts;

  @override
  Future<LabReferral> uploadAndRecognize(
    PickedReferralFile file, {
    String? familyMemberId,
  }) async {
    try {
      final ticket = await _repository.requestReferralUpload(
        filename: file.name,
        contentType: file.contentType,
      );
      await _uploadClient.post<void>(
        ticket.uploadUrl,
        data: FormData.fromMap({
          ...ticket.fields,
          'file': MultipartFile.fromBytes(
            file.bytes,
            filename: file.name,
            contentType: DioMediaType.parse(file.contentType),
          ),
        }),
      );
      final referralId = await _repository.confirmReferral(
        s3Key: ticket.key,
        familyMemberId: familyMemberId,
      );

      for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
        final referral = await _repository.referral(referralId);
        if (referral.status
            case LabReferralStatus.completed || LabReferralStatus.failed) {
          return referral;
        }
        await Future<void>.delayed(pollInterval);
      }
      throw const LabOcrTimeoutException();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<List<LabPriceOffer>> offers(String referralId) =>
      _repository.offers(referralId);

  @override
  Future<LabOrder> createOrder({
    required String referralId,
    required String labId,
  }) => _repository.createOrder(referralId: referralId, labId: labId);
}

class MockLabOcrService implements LabOcrService {
  const MockLabOcrService();

  @override
  Future<LabReferral> uploadAndRecognize(
    PickedReferralFile file, {
    String? familyMemberId,
  }) async => LabReferral(
    id: 'mock-referral',
    familyMemberId: familyMemberId,
    status: LabReferralStatus.completed,
    recognizedTests: const [
      {'name': 'Общий анализ крови'},
      {'name': 'Ферритин'},
      {'name': 'Витамин D'},
    ],
    createdAt: DateTime(2026, 8, 22),
  );

  @override
  Future<List<LabPriceOffer>> offers(String referralId) async => const [
    LabPriceOffer(
      labId: 'mock-lab',
      labName: 'Партнёрская лаборатория',
      totalPrice: 15000,
      priceForUser: 12000,
      discountPercent: 20,
    ),
  ];

  @override
  Future<LabOrder> createOrder({
    required String referralId,
    required String labId,
  }) async => LabOrder(
    id: 'mock-order',
    referralId: referralId,
    labId: labId,
    totalPrice: 12000,
    status: 'created',
    createdAt: DateTime(2026, 8, 22),
  );
}

class LabOcrTimeoutException implements Exception {
  const LabOcrTimeoutException();
}
