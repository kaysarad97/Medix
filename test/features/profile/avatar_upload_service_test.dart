import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/profile/data/repositories/profile_repository.dart';
import 'package:medix/features/profile/data/services/avatar_file_picker.dart';
import 'package:medix/features/profile/data/services/avatar_upload_service.dart';
import 'package:medix/features/profile/domain/entities/user_profile.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('отправляет multipart в хранилище и подтверждает S3-ключ', () async {
    final repository = _AvatarRepository();
    final (:dio, :adapter) = cannedDio({
      'POST https://storage.example/upload': (statusCode: 204, body: const {}),
    });
    final service = RemoteAvatarUploadService(repository, uploadClient: dio);

    await service.upload(
      PickedAvatarFile(
        name: 'avatar.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([1, 2, 3]),
      ),
    );

    expect(repository.requestedFilename, 'avatar.png');
    expect(repository.confirmedKey, 'avatars/u1/avatar.png');
    expect(adapter.requests.single.data.fields.single.key, 'policy');
    expect(adapter.requests.single.data.fields.single.value, 'signed');
    expect(adapter.requests.single.data.files.single.key, 'file');
  });
}

class _AvatarRepository extends MockProfileRepository {
  String? requestedFilename;
  String? confirmedKey;

  @override
  Future<AvatarUploadTicket> requestAvatarUpload({
    required String filename,
    required String contentType,
  }) async {
    requestedFilename = filename;
    return AvatarUploadTicket(
      uploadUrl: 'https://storage.example/upload',
      fields: const {'policy': 'signed'},
      key: 'avatars/u1/avatar.png',
      expiresAt: DateTime.utc(2026, 8, 21),
    );
  }

  @override
  Future<UserProfile> confirmAvatar(String s3Key) async {
    confirmedKey = s3Key;
    return MockProfileRepository.mockProfile;
  }
}
