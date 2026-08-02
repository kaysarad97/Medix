/// Уровень подписки.
///
/// Лежит в `shared/`: тариф показывает профиль (значок в шапке), а продают
/// его экраны подписки.
enum SubscriptionTier {
  free('Free', 'Basic'),
  silver('Silver', 'Silver'),
  gold('Gold', 'Gold');

  const SubscriptionTier(this.label, this.columnLabel);

  /// Подпись в шапке профиля.
  final String label;

  /// Заголовок колонки в таблице сравнения. Бесплатный тариф назван там
  /// «Basic», хотя в остальном коде это `free` — так в макете.
  final String columnLabel;
}
