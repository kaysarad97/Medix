import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user_profile.dart';
import '../repositories/profile_repository.dart';
import 'avatar_file_picker.dart';

abstract interface class AvatarUploadService {
  Future<UserProfile> upload(PickedAvatarFile file);
}

class MockAvatarUploadService implements AvatarUploadService {
  const MockAvatarUploadService(this._repository);

  final ProfileRepository _repository;

  @override
  Future<UserProfile> upload(PickedAvatarFile file) async {
    final ticket = await _repository.requestAvatarUpload(
      filename: file.name,
      contentType: file.contentType,
    );
    return _repository.confirmAvatar(ticket.key);
  }
}

/// Полный presigned POST: получить форму, отправить байты в хранилище,
/// подтвердить ключ на API и вернуть обновлённый профиль.
class RemoteAvatarUploadService implements AvatarUploadService {
  RemoteAvatarUploadService(this._repository, {Dio? uploadClient})
    : _uploadClient = uploadClient ?? Dio();

  final ProfileRepository _repository;
  final Dio _uploadClient;

  @override
  Future<UserProfile> upload(PickedAvatarFile file) async {
    try {
      final ticket = await _repository.requestAvatarUpload(
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
      return await _repository.confirmAvatar(ticket.key);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
