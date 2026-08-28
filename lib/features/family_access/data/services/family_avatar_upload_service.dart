import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/family_member.dart';
import '../../../profile/data/services/avatar_file_picker.dart';
import '../repositories/family_repository.dart';

abstract interface class FamilyAvatarUploadService {
  Future<FamilyMember> upload(String memberId, PickedAvatarFile file);
}

class MockFamilyAvatarUploadService implements FamilyAvatarUploadService {
  const MockFamilyAvatarUploadService(this._repository);

  final FamilyRepository _repository;

  @override
  Future<FamilyMember> upload(String memberId, PickedAvatarFile file) async {
    final ticket = await _repository.requestAvatarUpload(
      memberId,
      filename: file.name,
      contentType: file.contentType,
    );
    return _repository.confirmAvatar(memberId, ticket.key);
  }
}

/// Тот же presigned POST, что и у аватара пользователя
/// (`AvatarUploadService`), но форма и подтверждение — по конкретному члену
/// семьи, а не по своему профилю.
class RemoteFamilyAvatarUploadService implements FamilyAvatarUploadService {
  RemoteFamilyAvatarUploadService(this._repository, {Dio? uploadClient})
    : _uploadClient = uploadClient ?? Dio();

  final FamilyRepository _repository;
  final Dio _uploadClient;

  @override
  Future<FamilyMember> upload(String memberId, PickedAvatarFile file) async {
    try {
      final ticket = await _repository.requestAvatarUpload(
        memberId,
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
      return await _repository.confirmAvatar(memberId, ticket.key);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
