import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedAvatarFile {
  const PickedAvatarFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });

  final String name;
  final String contentType;
  final Uint8List bytes;
}

abstract interface class AvatarFilePicker {
  Future<PickedAvatarFile?> pick();
}

class PlatformAvatarFilePicker implements AvatarFilePicker {
  const PlatformAvatarFilePicker();

  static const types = XTypeGroup(
    label: 'JPG, PNG',
    extensions: ['jpg', 'jpeg', 'png'],
    mimeTypes: ['image/jpeg', 'image/png'],
    uniformTypeIdentifiers: ['public.jpeg', 'public.png'],
  );

  @override
  Future<PickedAvatarFile?> pick() async {
    final file = await openFile(acceptedTypeGroups: [types]);
    if (file == null) return null;
    final extension = file.name.split('.').last.toLowerCase();
    return PickedAvatarFile(
      name: file.name,
      contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
      bytes: await file.readAsBytes(),
    );
  }
}
