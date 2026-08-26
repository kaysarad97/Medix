import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/doctor_cabinet/data/repositories/doctor_media_repository.dart';

import '../../helpers/canned_dio.dart';

void main() {
  Map<String, Object?> doctor() => {
    'id': '00000000-0000-0000-0000-000000000010',
    'user_id': '00000000-0000-0000-0000-000000000011',
    'full_name': 'Имя Фамилия',
    'phone': null,
    'email': 'doctor@medix.kz',
    'specialty': 'Кардиолог',
    'license_number': 'LIC-1',
    'clinic_id': null,
    'verification_status': 'pending',
    'invited_by': null,
    'reviewed_by': null,
    'reviewed_at': null,
    'rejection_reason': null,
    'created_at': '2026-08-21T06:00:00Z',
  };

  test('загружает сертификат в хранилище и подтверждает ключ', () async {
    const uploadUrl = 'https://storage.example/doctor-credentials';
    const key = 'doctors/d1/credentials/diploma.pdf';
    final (:dio, :adapter) = cannedDio({
      'POST /doctors/me/credentials/upload-url': (
        statusCode: 200,
        body: {
          'upload_url': uploadUrl,
          'fields': {'policy': 'signed-policy', 'key': key},
          'key': key,
          'expires_at': '2026-08-21T06:10:00Z',
        },
      ),
      'POST /doctors/me/credentials': (statusCode: 200, body: doctor()),
    });
    final (dio: uploadDio, adapter: uploadAdapter) = cannedDio({
      'POST $uploadUrl': (statusCode: 204, body: {}),
    });

    await RemoteDoctorMediaRepository(
      dio,
      uploadClient: uploadDio,
    ).uploadCredentials(
      filename: 'diploma.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(adapter.requests, hasLength(2));
    expect(adapter.requests.first.data, {
      'filename': 'diploma.pdf',
      'content_type': 'application/pdf',
    });
    expect(adapter.requests.last.data, {'credential_s3_key': key});
    expect(uploadAdapter.requests.single.path, uploadUrl);
    final form = uploadAdapter.requests.single.data as FormData;
    expect(Map.fromEntries(form.fields)['policy'], 'signed-policy');
    expect(form.files.single.key, 'file');
    expect(form.files.single.value.filename, 'diploma.pdf');
  });

  test(
    'фотография использует собственные endpoint и ключ подтверждения',
    () async {
      const uploadUrl = 'https://storage.example/doctor-photo';
      const key = 'doctors/d1/photo/avatar.png';
      final (:dio, :adapter) = cannedDio({
        'POST /doctors/me/photo/upload-url': (
          statusCode: 200,
          body: {
            'upload_url': uploadUrl,
            'fields': <String, String>{},
            'key': key,
            'expires_at': '2026-08-21T06:10:00Z',
          },
        ),
        'POST /doctors/me/photo': (statusCode: 200, body: doctor()),
      });
      final (dio: uploadDio, adapter: _) = cannedDio({
        'POST $uploadUrl': (statusCode: 204, body: {}),
      });

      await RemoteDoctorMediaRepository(
        dio,
        uploadClient: uploadDio,
      ).uploadPhoto(
        filename: 'avatar.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([137, 80, 78, 71]),
      );

      expect(adapter.requests.first.path, '/doctors/me/photo/upload-url');
      expect(adapter.requests.last.data, {'photo_s3_key': key});
    },
  );
}
