import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedDoctorFile {
  const PickedDoctorFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class DoctorFilePicker {
  Future<PickedDoctorFile?> pickCertificate();

  /// Фотография врача — только изображения, PDF сертификатов сюда не
  /// подходит. Отдельный метод, а не параметр у [pickCertificate]: у
  /// сертификата и фото разные системные диалоги выбора и разные типы
  /// файлов, совмещать их в один вызов только запутывало бы вызывающих.
  Future<PickedDoctorFile?> pickPhoto();
}

class PlatformDoctorFilePicker implements DoctorFilePicker {
  const PlatformDoctorFilePicker();

  static const _certificateTypes = XTypeGroup(
    label: 'PDF, JPG, PNG',
    extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['com.adobe.pdf', 'public.jpeg', 'public.png'],
  );

  static const _photoTypes = XTypeGroup(
    label: 'JPG, PNG',
    extensions: ['jpg', 'jpeg', 'png'],
    mimeTypes: ['image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
  );

  @override
  Future<PickedDoctorFile?> pickCertificate() async {
    final file = await openFile(acceptedTypeGroups: [_certificateTypes]);
    if (file == null) return null;

    return PickedDoctorFile(
      name: file.name,
      contentType: _contentType(file.name),
      bytes: await file.readAsBytes(),
    );
  }

  @override
  Future<PickedDoctorFile?> pickPhoto() async {
    final file = await openFile(acceptedTypeGroups: [_photoTypes]);
    if (file == null) return null;

    return PickedDoctorFile(
      name: file.name,
      contentType: _contentType(file.name),
      bytes: await file.readAsBytes(),
    );
  }

  static String _contentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };
  }
}
