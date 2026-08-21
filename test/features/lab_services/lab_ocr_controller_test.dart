import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/lab_services/data/services/lab_ocr_service.dart';
import 'package:medix/features/lab_services/data/services/referral_file_picker.dart';
import 'package:medix/features/lab_services/domain/entities/lab_workflow.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_ocr_providers.dart';

void main() {
  test('выбранный файл проходит OCR и сохраняет результат', () async {
    final service = _OcrService();
    final container = ProviderContainer(
      overrides: [
        referralFilePickerProvider.overrideWithValue(const _Picker()),
        labOcrServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(labOcrControllerProvider.notifier)
        .upload(familyMemberId: 'family-1');

    final state = container.read(labOcrControllerProvider);
    expect(state.value?.id, 'ref-1');
    expect(service.file?.name, 'referral.pdf');
    expect(service.familyMemberId, 'family-1');
  });

  test('отмена системного picker не запускает OCR', () async {
    final service = _OcrService();
    final container = ProviderContainer(
      overrides: [
        referralFilePickerProvider.overrideWithValue(const _CancelledPicker()),
        labOcrServiceProvider.overrideWithValue(service),
      ],
    );
    addTearDown(container.dispose);

    await container.read(labOcrControllerProvider.notifier).upload();

    expect(service.file, isNull);
    expect(container.read(labOcrControllerProvider).value, isNull);
  });
}

class _Picker implements ReferralFilePicker {
  const _Picker();

  @override
  Future<PickedReferralFile?> pick() async => PickedReferralFile(
    name: 'referral.pdf',
    contentType: 'application/pdf',
    bytes: Uint8List.fromList([1]),
  );
}

class _CancelledPicker implements ReferralFilePicker {
  const _CancelledPicker();

  @override
  Future<PickedReferralFile?> pick() async => null;
}

class _OcrService extends MockLabOcrService {
  PickedReferralFile? file;
  String? familyMemberId;

  @override
  Future<LabReferral> uploadAndRecognize(
    PickedReferralFile file, {
    String? familyMemberId,
  }) async {
    this.file = file;
    this.familyMemberId = familyMemberId;
    return LabReferral(
      id: 'ref-1',
      familyMemberId: familyMemberId,
      status: LabReferralStatus.completed,
      recognizedTests: const [],
      createdAt: DateTime.utc(2026, 8, 22),
    );
  }
}
