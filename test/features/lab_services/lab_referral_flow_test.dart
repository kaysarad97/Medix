import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medix/core/theme/app_theme.dart';
import 'package:medix/features/lab_services/data/services/lab_ocr_service.dart';
import 'package:medix/features/lab_services/data/services/referral_file_picker.dart';
import 'package:medix/features/lab_services/domain/entities/lab_workflow.dart';
import 'package:medix/features/lab_services/presentation/providers/lab_ocr_providers.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_offers_screen.dart';
import 'package:medix/features/lab_services/presentation/screens/lab_referral_screen.dart';
import 'package:medix/l10n/app_localizations.dart';

void main() {
  Widget app(Widget child, {required LabOcrService service}) => ProviderScope(
    overrides: [
      referralFilePickerProvider.overrideWithValue(const _Picker()),
      labOcrServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );

  testWidgets('загружает направление и показывает распознанные анализы', (
    tester,
  ) async {
    final service = _Service();
    await tester.pumpWidget(app(const LabReferralScreen(), service: service));
    await tester.pump();

    await tester.tap(find.text('Выбрать направление'));
    await tester.pumpAndSettle();

    expect(service.uploaded, isTrue);
    expect(find.textContaining('Общий анализ крови'), findsOneWidget);
    expect(find.text('Сравнить цены'), findsOneWidget);
  });

  testWidgets('OCR-предложение создаёт заказ через API service', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final service = _Service();
    await tester.pumpWidget(
      app(const LabOffersScreen(referralId: 'ref-1'), service: service),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лаборатория 1'), findsOneWidget);
    await tester.tap(find.text('Оформить заказ'));
    await tester.pumpAndSettle();

    expect(service.orderedReferralId, 'ref-1');
    expect(service.orderedLabId, 'lab-1');
    expect(find.text('Заказ order-1 создан'), findsOneWidget);
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

class _Service implements LabOcrService {
  bool uploaded = false;
  String? orderedReferralId;
  String? orderedLabId;

  @override
  Future<LabReferral> uploadAndRecognize(
    PickedReferralFile file, {
    String? familyMemberId,
  }) async {
    uploaded = true;
    return LabReferral(
      id: 'ref-1',
      status: LabReferralStatus.completed,
      recognizedTests: const [
        {'name': 'Общий анализ крови'},
      ],
      createdAt: DateTime.utc(2026, 8, 22),
    );
  }

  @override
  Future<List<LabPriceOffer>> offers(String referralId) async => const [
    LabPriceOffer(
      labId: 'lab-1',
      labName: 'Лаборатория 1',
      totalPrice: 12000,
      priceForUser: 10000,
      discountPercent: 17,
    ),
  ];

  @override
  Future<LabOrder> createOrder({
    required String referralId,
    required String labId,
  }) async {
    orderedReferralId = referralId;
    orderedLabId = labId;
    return LabOrder(
      id: 'order-1',
      referralId: referralId,
      labId: labId,
      totalPrice: 10000,
      status: 'created',
      createdAt: DateTime.utc(2026, 8, 22),
    );
  }
}
