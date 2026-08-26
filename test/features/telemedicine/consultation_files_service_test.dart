import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/telemedicine/data/repositories/consultations_repository.dart';
import 'package:medix/features/telemedicine/data/services/consultation_file_picker.dart';
import 'package:medix/features/telemedicine/data/services/consultation_files_service.dart';
import 'package:medix/features/telemedicine/domain/entities/consultation.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('отправляет multipart и подтверждает файл консультации', () async {
    final repository = _ConsultationsRepository();
    final (:dio, :adapter) = cannedDio({
      'POST https://storage.example/upload': (statusCode: 204, body: const {}),
    });
    final service = RemoteConsultationFilesService(
      repository,
      uploadClient: dio,
    );

    final uploaded = await service.upload(
      'c1',
      PickedConsultationFile(
        name: 'result.pdf',
        contentType: 'application/pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(repository.requestedConsultationId, 'c1');
    expect(repository.requestedFilename, 'result.pdf');
    expect(repository.requestedContentType, 'application/pdf');
    expect(repository.confirmedKey, 'consultations/c1/files/result.pdf');
    expect(uploaded.id, 'f1');
    expect(adapter.requests.single.data.fields.single.key, 'policy');
    expect(adapter.requests.single.data.fields.single.value, 'signed');
    expect(adapter.requests.single.data.files.single.key, 'file');
  });
}

class _ConsultationsRepository extends ConsultationsRepository {
  _ConsultationsRepository() : super(Dio());

  String? requestedConsultationId;
  String? requestedFilename;
  String? requestedContentType;
  String? confirmedKey;

  @override
  Future<ConsultationFileUpload> requestFileUpload(
    String consultationId, {
    required String filename,
    required String contentType,
  }) async {
    requestedConsultationId = consultationId;
    requestedFilename = filename;
    requestedContentType = contentType;
    return ConsultationFileUpload(
      uploadUrl: 'https://storage.example/upload',
      fields: const {'policy': 'signed'},
      key: 'consultations/c1/files/result.pdf',
      expiresAt: DateTime.utc(2026, 8, 24),
    );
  }

  @override
  Future<ConsultationFile> confirmFileUpload(
    String consultationId, {
    required String s3Key,
  }) async {
    confirmedKey = s3Key;
    return ConsultationFile(
      id: 'f1',
      consultationId: consultationId,
      uploadedBy: 'u1',
      createdAt: DateTime.utc(2026, 8, 24),
    );
  }
}
