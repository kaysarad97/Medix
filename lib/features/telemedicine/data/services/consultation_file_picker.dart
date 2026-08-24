import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedConsultationFile {
  const PickedConsultationFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class ConsultationFilePicker {
  Future<PickedConsultationFile?> pick();
}

class PlatformConsultationFilePicker implements ConsultationFilePicker {
  const PlatformConsultationFilePicker();

  static const types = XTypeGroup(
    label: 'PDF, JPG, PNG',
    extensions: ['pdf', 'jpg', 'jpeg', 'png'],
    mimeTypes: ['application/pdf', 'image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['com.adobe.pdf', 'public.jpeg', 'public.png'],
  );

  @override
  Future<PickedConsultationFile?> pick() async {
    final file = await openFile(acceptedTypeGroups: [types]);
    if (file == null) return null;

    final extension = file.name.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    return PickedConsultationFile(
      name: file.name,
      contentType: contentType,
      bytes: await file.readAsBytes(),
    );
  }
}
