import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/core/widgets/primary_button.dart';
import 'package:medix/features/doctor_cabinet/data/repositories/doctor_media_repository.dart';
import 'package:medix/features/doctor_cabinet/data/services/doctor_file_picker.dart';
import 'package:medix/features/doctor_cabinet/presentation/providers/doctor_cabinet_providers.dart';
import 'package:medix/features/doctor_cabinet/presentation/screens/doctor_certificates_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

import '../../helpers/fake_doctor_cabinet_repository.dart';
import '../../helpers/test_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool showUploadRow = false,
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
          home: DoctorCertificatesScreen(showUploadRow: showUploadRow),
        ),
      ),
    );
  }

  testWidgets('рисует заголовок и сетку сертификатов', (tester) async {
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ваши сертификаты'), findsOneWidget);
    expect(find.text('Документ 1.pdf'), findsOneWidget);
    expect(find.text('Документ 2.pdf'), findsOneWidget);
    expect(find.text('Загрузить Сертификат'), findsNothing);
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('showUploadRow рисует отдельный шаг регистрации', (tester) async {
    await pumpScreen(tester, showUploadRow: true);
    await tester.pump();
    await tester.pump();

    expect(find.text('Ваши сертификаты'), findsOneWidget);
    expect(find.text('Загрузить Сертификат'), findsOneWidget);
    expect(find.text('Специализация'), findsOneWidget);
    expect(find.text('Документ 1.pdf'), findsNothing);
    expect(
      find.byKey(const ValueKey('doctor-registration-certificate-picker')),
      findsOneWidget,
    );
    expect(find.widgetWithText(PrimaryButton, 'Далее'), findsOneWidget);
  });

  testWidgets('выбранный сертификат загружается и показывает результат', (
    tester,
  ) async {
    final repository = _RecordingMediaRepository();
    await pumpScreen(
      tester,
      showUploadRow: true,
      picker: _FakeFilePicker(
        PickedDoctorFile(
          name: 'diploma.pdf',
          contentType: 'application/pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Загрузить Сертификат'));
    await tester.pumpAndSettle();

    expect(repository.uploadedFilename, 'diploma.pdf');
    expect(repository.uploadedContentType, 'application/pdf');
    expect(find.text('diploma.pdf'), findsOneWidget);
    expect(find.text('Сертификат загружен'), findsOneWidget);
  });

  testWidgets('отмена выбора файла не запускает загрузку', (tester) async {
    final repository = _RecordingMediaRepository();
    await pumpScreen(
      tester,
      showUploadRow: true,
      picker: const _FakeFilePicker(null),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Загрузить Сертификат'));
    await tester.pumpAndSettle();

    expect(repository.uploadedFilename, isNull);
    expect(find.text('Сертификат загружен'), findsNothing);
  });

  testWidgets('ошибка загрузки показывается без падения экрана', (
    tester,
  ) async {
    final repository = _RecordingMediaRepository(shouldFail: true);
    await pumpScreen(
      tester,
      showUploadRow: true,
      picker: _FakeFilePicker(
        PickedDoctorFile(
          name: 'diploma.pdf',
          contentType: 'application/pdf',
          bytes: Uint8List(1),
        ),
      ),
      mediaRepository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Загрузить Сертификат'));
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить сертификат'), findsOneWidget);
    expect(find.text('Загрузить Сертификат'), findsOneWidget);
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
  }) async {
    if (shouldFail) throw Exception('upload failed');
    uploadedFilename = filename;
    uploadedContentType = contentType;
  }

  @override
  Future<void> uploadPhoto({
    required String filename,
    required String contentType,
    required Uint8List bytes,
  }) async {}
}
