import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/subscription_plan.dart';
import '../plan_features.dart';
import 'subscriptions_repository.dart';

/// Тарифы и оформление подписки поверх FastAPI-бэкенда.
///
/// Платёжного шлюза у сервера нет: `POST /subscriptions` заводит подписку и
/// сразу возвращает платёж со статусом `paid`. Поэтому данные карты с
/// [CardFormScreen] никуда не уходят — форма остаётся ради макета и ради
/// того дня, когда шлюз появится, а подписку оформляет сам запрос.
class RemoteSubscriptionsRepository implements SubscriptionsRepository {
  const RemoteSubscriptionsRepository(this._dio);

  final Dio _dio;

  /// Таблица сравнения приходит не с сервера — см. [designPlanFeatures].
  @override
  Future<List<PlanFeature>> features() async => designPlanFeatures;

  @override
  Future<List<SubscriptionPlan>> plans() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiEndpoints.plans);

      return [
        for (final item in response.data ?? const [])
          if (item case final Map<String, dynamic> plan)
            if (SubscriptionTier.fromCode(plan['code']) case final tier
                when tier != SubscriptionTier.free)
              SubscriptionPlan(
                tier: tier,
                // Цена приходит дробным числом (4990.0), а в макете она без
                // копеек — и в тенге их не бывает.
                pricePerMonth: (plan['monthly_price'] as num).round(),
              ),
      ];
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<SubscriptionCancellation> cancel() async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.mySubscription,
      );
      final json = response.data!;
      return SubscriptionCancellation(
        periodEnd: DateTime.parse(json['period_end'] as String).toLocal(),
        cancelAtPeriodEnd: json['cancel_at_period_end'] as bool,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Карта не отправляется никуда: принимать её серверу нечем, и подписку
  /// оформляет сам запрос.
  @override
  Future<PaymentOutcome> pay(
    CardDetails card, {
    required SubscriptionTier tier,
  }) async {
    final code = tier.code;
    // Бесплатный тариф не оформляют: подписки на него на сервере нет.
    if (code == null) return PaymentOutcome.failure;

    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.subscriptions,
        data: {'plan_code': code},
      );
      return PaymentOutcome.success;
    } on DioException {
      // Экран результата различает только «прошло» и «не прошло», текста
      // ошибки в макете нет — поэтому исключение сюда не пробрасывается.
      return PaymentOutcome.failure;
    }
  }
}
