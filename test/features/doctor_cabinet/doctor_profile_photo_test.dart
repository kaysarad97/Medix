import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/doctor_cabinet/data/repositories/doctor_media_repository.dart';
import 'package:medix/features/doctor_cabinet/data/services/doctor_file_picker.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_profile_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

/// Загрузка фото врача с «Ваш Профиль» — тот же путь, что и у сертификата
/// в `doctor_certificates_screen_test.dart`, но на другом экране и через
/// `pickPhoto()`, а не `pickCertificate()`.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    DoctorFilePicker? picker,
    DoctorMediaRepository? mediaRepository,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          doctorCabinetRepositoryProvider.overrideWithValue(
            const FakeDoctorCabinetRepository(),
          ),
          if (picker != null)
            doctorFilePickerProvider.overrideWithValue(picker),
          if (mediaRepository != null)
            doctorMediaRepositoryProvider.overrideWithValue(mediaRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DoctorOwnProfileScreen(),
        ),
      ),
    );
  }

  testWidgets('подпись «изменить фото» видна под фото', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('изменить фото'), findsOneWidget);
  });

  testWidgets('выбранное фото загружается и показывает результат', (
    tester,
  ) async {
    final repository = _RecordingMediaRepository();
    await pumpScreen(
      tester,
      picker: _FakeFilePicker(
        PickedDoctorFile(
          name: 'photo.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('изменить фото'));
    await tester.pumpAndSettle();

    expect(repository.uploadedFilename, 'photo.jpg');
    expect(repository.uploadedContentType, 'image/jpeg');
    expect(find.text('Фото обновлено'), findsOneWidget);
  });

  testWidgets('отмена выбора файла не запускает загрузку', (tester) async {
    final repository = _RecordingMediaRepository();
    await pumpScreen(
      tester,
      picker: const _FakeFilePicker(null),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('изменить фото'));
    await tester.pumpAndSettle();

    expect(repository.uploadedFilename, isNull);
    expect(find.text('Фото обновлено'), findsNothing);
  });

  testWidgets('ошибка загрузки показывается без падения экрана', (
    tester,
  ) async {
    final repository = _RecordingMediaRepository(shouldFail: true);
    await pumpScreen(
      tester,
      picker: _FakeFilePicker(
        PickedDoctorFile(
          name: 'photo.jpg',
          contentType: 'image/jpeg',
          bytes: Uint8List(1),
        ),
      ),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('изменить фото'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить фото'), findsOneWidget);
    expect(find.text('изменить фото'), findsOneWidget);
  });
}

class _FakeFilePicker implements DoctorFilePicker {
  const _FakeFilePicker(this.file);

  final PickedDoctorFile? file;

  @override
  Future<PickedDoctorFile?> pickCertificate() async => file;

  @override
  Future<PickedDoctorFile?> pickPhoto() async => file;
}

class _RecordingMediaRepository implements DoctorMediaRepository {
  _RecordingMediaRepository({this.shouldFail = false});

  final bool shouldFail;
  String? uploadedFilename;
  String? uploadedContentType;

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
  }) async {
    if (shouldFail) throw Exception('upload failed');
    uploadedFilename = filename;
    uploadedContentType = contentType;
  }
}
