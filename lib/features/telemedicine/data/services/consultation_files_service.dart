import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/consultation.dart';
import '../repositories/consultations_repository.dart';
import 'consultation_file_picker.dart';

abstract interface class ConsultationFilesService {
  Future<List<ConsultationFile>> files(String consultationId);

  Future<ConsultationFile> upload(
    String consultationId,
    PickedConsultationFile file,
  );

  Future<ConsultationFileDownload> download(
    String consultationId,
    String fileId,
  );
}

/// Полный presigned POST для вложения консультации: API выдаёт форму,
/// байты отправляются напрямую в хранилище, после чего ключ подтверждается.
class RemoteConsultationFilesService implements ConsultationFilesService {
  RemoteConsultationFilesService(this._repository, {Dio? uploadClient})
    : _uploadClient = uploadClient ?? Dio();

  final ConsultationsRepository _repository;
  final Dio _uploadClient;

  @override
  Future<List<ConsultationFile>> files(String consultationId) =>
      _repository.files(consultationId);

  @override
  Future<ConsultationFile> upload(
    String consultationId,
    PickedConsultationFile file,
  ) async {
    try {
      final ticket = await _repository.requestFileUpload(
        consultationId,
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
      return await _repository.confirmFileUpload(
        consultationId,
        s3Key: ticket.key,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  @override
  Future<ConsultationFileDownload> download(
    String consultationId,
    String fileId,
  ) => _repository.fileDownload(consultationId, fileId);
}
