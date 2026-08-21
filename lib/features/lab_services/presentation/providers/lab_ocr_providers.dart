import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_mode.dart';
import '../../data/services/lab_ocr_service.dart';
import '../../data/services/referral_file_picker.dart';
import '../../domain/entities/lab_workflow.dart';
import 'lab_services_providers.dart';

final referralFilePickerProvider = Provider<ReferralFilePicker>(
  (ref) => const PlatformReferralFilePicker(),
);

final labOcrServiceProvider = Provider<LabOcrService>((ref) {
  if (useMocks) return const MockLabOcrService();
  return RemoteLabOcrService(ref.watch(labApiRepositoryProvider));
});

class LabOcrController extends AsyncNotifier<LabReferral?> {
  @override
  Future<LabReferral?> build() async => null;

  Future<void> upload({String? familyMemberId}) async {
    final file = await ref.read(referralFilePickerProvider).pick();
    if (file == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(labOcrServiceProvider)
          .uploadAndRecognize(file, familyMemberId: familyMemberId),
    );
  }

  void reset() => state = const AsyncData(null);
}

final labOcrControllerProvider =
    AsyncNotifierProvider<LabOcrController, LabReferral?>(LabOcrController.new);

final labOcrOffersProvider = FutureProvider.autoDispose
    .family<List<LabPriceOffer>, String>(
      (ref, referralId) => ref.watch(labOcrServiceProvider).offers(referralId),
    );
