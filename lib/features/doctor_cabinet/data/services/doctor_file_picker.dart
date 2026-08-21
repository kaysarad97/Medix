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
}

class PlatformDoctorFilePicker implements DoctorFilePicker {
  const PlatformDoctorFilePicker();

  static const _certificateTypes = XTypeGroup(
    label: 'PDF, JPG, PNG',
    extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['com.adobe.pdf', 'public.jpeg', 'public.png'],
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
