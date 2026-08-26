/// Уровень подписки.
///
/// Лежит в `shared/`: тариф показывает профиль (значок в шапке), а продают
/// его экраны подписки.
///
/// Тарифа Gold больше нет: на сервере он отключён (`GET /plans` отдаёт один
/// silver), а 20 августа 2026 его сняли и с продажи в приложении. Осталось
/// два состояния — «подписки нет» и Silver. Макеты подписки и шапки профиля
/// по-прежнему нарисованы под три тарифа, это вопрос к дизайнеру.
enum SubscriptionTier {
  free('Free', 'Basic', null),
  silver('Silver', 'Silver', 'silver');

  const SubscriptionTier(this.label, this.columnLabel, this.code);

  /// Подпись в шапке профиля.
  final String label;

  /// Заголовок колонки в таблице сравнения. Бесплатный тариф назван там
  /// «Basic», хотя в остальном коде это `free` — так в макете.
  final String columnLabel;

  /// `plan_code` на сервере. У бесплатного его нет: отсутствие подписки —
  /// это 404 на `/subscriptions/me`, а не отдельный тариф.
  final String? code;

  /// Тариф по коду с сервера. Незнакомый код — то же, что отсутствие
  /// подписки: платные разделы «на всякий случай» не открываем.
  static SubscriptionTier fromCode(Object? code) =>
      values.firstWhere((tier) => tier.code == code, orElse: () => free);
}
