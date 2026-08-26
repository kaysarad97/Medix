import 'package:flutter_test/flutter_test.dart';
import 'package:medix/features/lab_services/data/repositories/lab_api_repository.dart';
import 'package:medix/features/lab_services/domain/entities/lab_workflow.dart';

import '../../helpers/canned_dio.dart';

void main() {
  test('направление: билет загрузки, подтверждение и результат OCR', () async {
    final (:dio, :adapter) = cannedDio({
      'POST /lab/referrals/upload-url': (
        statusCode: 200,
        body: {
          'upload_url': 'https://storage.example/upload',
          'fields': {'key': 'referrals/u1/file.pdf', 'policy': 'signed'},
          'key': 'referrals/u1/file.pdf',
          'expires_at': '2026-08-21T10:00:00',
        },
      ),
      'POST /lab/referrals': (statusCode: 202, body: {'referral_id': 'ref-1'}),
      'GET /lab/referrals/ref-1': (
        statusCode: 200,
        body: {
          'id': 'ref-1',
          'family_member_id': null,
          'status': 'completed',
          'recognized_tests': [
            {'name': 'Общий анализ крови'},
          ],
          'failure_reason': null,
          'created_at': '2026-08-21T09:00:00',
        },
      ),
    });
    final repository = LabApiRepository(dio);

    final ticket = await repository.requestReferralUpload(
      filename: 'referral.pdf',
      contentType: 'application/pdf',
    );
    final id = await repository.confirmReferral(s3Key: ticket.key);
    final referral = await repository.referral(id);

    expect(ticket.fields['policy'], 'signed');
    expect(referral.status, LabReferralStatus.completed);
    expect(referral.recognizedTests.single['name'], 'Общий анализ крови');
    expect(adapter.requests[1].data, {
      's3_key': 'referrals/u1/file.pdf',
      'family_member_id': null,
    });
  });

  test('предложения читают серверные скидки, заказ создаётся', () async {
    final (:dio, :adapter) = cannedDio({
      'GET /lab/offers': (
        statusCode: 200,
        body: [
          {
            'lab': {'id': 'lab-1', 'name': 'Олимп'},
            'total_price': 5000.0,
            'price_for_user': 4500.0,
            'discount_percent': 10,
            'discount_reason': 'silver',
            'prices_updated_at': '2026-08-20T12:00:00',
          },
        ],
      ),
      'POST /lab/orders': (
        statusCode: 201,
        body: {
          'id': 'order-1',
          'referral_id': 'ref-1',
          'lab_id': 'lab-1',
          'total_price': 4500.0,
          'status': 'pending',
          'created_at': '2026-08-21T09:30:00',
        },
      ),
    });
    final repository = LabApiRepository(dio);

    final offer = (await repository.offers('ref-1')).single;
    final order = await repository.createOrder(
      referralId: 'ref-1',
      labId: offer.labId,
    );

    expect(offer.priceForUser, 4500);
    expect(order.id, 'order-1');
    expect(adapter.requests.first.queryParameters['referral_id'], 'ref-1');
  });

  test('заказы и результаты доступны после перезапуска', () async {
    final (:dio, :adapter) = cannedDio({
      'GET /lab/orders': (
        statusCode: 200,
        body: [
          {
            'id': 'order-1',
            'referral_id': 'ref-1',
            'lab_id': 'lab-1',
            'total_price': 4500.0,
            'status': 'completed',
            'created_at': '2026-08-21T09:30:00',
          },
        ],
      ),
      'GET /lab/results': (
        statusCode: 200,
        body: [
          {
            'id': 'result-1',
            'lab_order_id': 'order-1',
            'created_at': '2026-08-21T11:00:00',
          },
        ],
      ),
      'GET /lab/results/result-1/download-url': (
        statusCode: 200,
        body: {
          'download_url': 'https://storage.example/result.pdf',
          'expires_at': '2026-08-21T12:00:00',
        },
      ),
    });
    final repository = LabApiRepository(dio);

    final order = (await repository.orders()).single;
    final result = (await repository.results(
      familyMemberId: 'family-1',
    )).single;
    final download = await repository.resultDownload(result.id);

    expect(order.status, 'completed');
    expect(download.url, endsWith('result.pdf'));
    expect(adapter.requests[1].queryParameters['family_member_id'], 'family-1');
  });
}
