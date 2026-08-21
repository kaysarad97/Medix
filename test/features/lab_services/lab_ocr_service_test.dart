import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/lab_services/data/repositories/lab_api_repository.dart';
import 'package:medix/features/lab_services/data/services/lab_ocr_service.dart';
import 'package:medix/features/lab_services/data/services/referral_file_picker.dart';
import 'package:medix/features/lab_services/domain/entities/lab_workflow.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('загружает multipart, подтверждает направление и ждёт OCR', () async {
    final repository = _LabApi();
    final (:dio, :adapter) = cannedDio({
      'POST https://storage.example/referral': (
        statusCode: 204,
        body: const {},
      ),
    });
    final service = RemoteLabOcrService(
      repository,
      uploadClient: dio,
      pollInterval: Duration.zero,
      maxPollAttempts: 3,
    );

    final result = await service.uploadAndRecognize(
      PickedReferralFile(
        name: 'referral.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
      familyMemberId: 'family-1',
    );

    expect(repository.confirmedKey, 'referrals/u1/referral.pdf');
    expect(repository.familyMemberId, 'family-1');
    expect(repository.pollCalls, 2);
    expect(result.status, LabReferralStatus.completed);
    expect(adapter.requests.single.data.files.single.key, 'file');
  });

  test('останавливает ожидание после лимита попыток', () async {
    final repository = _LabApi(alwaysPending: true);
    final (:dio, :adapter) = cannedDio({
      'POST https://storage.example/referral': (
        statusCode: 204,
        body: const {},
      ),
    });
    final service = RemoteLabOcrService(
      repository,
      uploadClient: dio,
      pollInterval: Duration.zero,
      maxPollAttempts: 2,
    );

    await expectLater(
      service.uploadAndRecognize(
        PickedReferralFile(
          name: 'referral.pdf',
          contentType: 'application/pdf',
          bytes: Uint8List(0),
        ),
      ),
      throwsA(isA<LabOcrTimeoutException>()),
    );
    expect(repository.pollCalls, 2);
    expect(adapter.requests, hasLength(1));
  });
}

class _LabApi extends LabApiRepository {
  _LabApi({this.alwaysPending = false}) : super(Dio());

  final bool alwaysPending;
  int pollCalls = 0;
  String? confirmedKey;
  String? familyMemberId;

  @override
  Future<ReferralUploadTicket> requestReferralUpload({
    required String filename,
    required String contentType,
  }) async => ReferralUploadTicket(
    uploadUrl: 'https://storage.example/referral',
    fields: const {'policy': 'signed'},
    key: 'referrals/u1/referral.pdf',
    expiresAt: DateTime.utc(2026, 8, 22),
  );

  @override
  Future<String> confirmReferral({
    required String s3Key,
    String? familyMemberId,
  }) async {
    confirmedKey = s3Key;
    this.familyMemberId = familyMemberId;
    return 'ref-1';
  }

  @override
  Future<LabReferral> referral(String id) async {
    pollCalls++;
    final completed = !alwaysPending && pollCalls > 1;
    return LabReferral(
      id: id,
      status: completed
          ? LabReferralStatus.completed
          : LabReferralStatus.processing,
      recognizedTests: completed
          ? const [
              {'name': 'Общий анализ крови'},
            ]
          : const [],
      createdAt: DateTime.utc(2026, 8, 22),
    );
  }
}
