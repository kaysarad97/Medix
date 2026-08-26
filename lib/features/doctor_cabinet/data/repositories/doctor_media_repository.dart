import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';

abstract interface class DoctorMediaRepository {
  Future<void> uploadCredentials({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });

  Future<void> uploadPhoto({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  });
}

/// Загрузка документов и фотографии врача через presigned POST.
class RemoteDoctorMediaRepository implements DoctorMediaRepository {
  RemoteDoctorMediaRepository(this._api, {Dio? uploadClient})
    : _uploadClient = uploadClient ?? Dio();

  final Dio _api;
  final Dio _uploadClient;

  @override
  Future<void> uploadCredentials({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) => _upload(
    uploadUrlEndpoint: ApiEndpoints.myDoctorCredentialsUploadUrl,
    confirmEndpoint: ApiEndpoints.myDoctorCredentials,
    confirmationKey: 'credential_s3_key',
    filename: filename,
    contentType: contentType,
    bytes: bytes,
  );

  @override
  Future<void> uploadPhoto({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) => _upload(
    uploadUrlEndpoint: ApiEndpoints.myDoctorPhotoUploadUrl,
    confirmEndpoint: ApiEndpoints.myDoctorPhoto,
    confirmationKey: 'photo_s3_key',
    filename: filename,
    contentType: contentType,
    bytes: bytes,
  );

  Future<void> _upload({
    required String uploadUrlEndpoint,
    required String confirmEndpoint,
    required String confirmationKey,
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {
    try {
      final ticketResponse = await _api.post<Map<String, dynamic>>(
        uploadUrlEndpoint,
        data: {'filename': filename, 'content_type': contentType},
      );
      final ticket = _UploadTicket.fromJson(ticketResponse.data!);
      final form = FormData.fromMap({
        ...ticket.fields,
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(contentType),
        ),
      });

      await _uploadClient.post<void>(ticket.uploadUrl, data: form);
      await _api.post<Map<String, dynamic>>(
        confirmEndpoint,
        data: {confirmationKey: ticket.key},
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

class MockDoctorMediaRepository implements DoctorMediaRepository {
  const MockDoctorMediaRepository();

  @override
  Future<void> uploadCredentials({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {}

  @override
  Future<void> uploadPhoto({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {}
}

class _UploadTicket {
  const _UploadTicket({
    required this.uploadUrl,
    required this.fields,
    required this.key,
  });

  factory _UploadTicket.fromJson(Map<String, dynamic> json) => _UploadTicket(
    uploadUrl: json['upload_url'] as String,
    fields: Map<String, String>.from(json['fields'] as Map),
    key: json['key'] as String,
  );

  final String uploadUrl;
  final Map<String, String> fields;
  final String key;
}
