import '../../../../shared/models/subscription_tier.dart';

/// Пользователь MedIx.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.subscription = SubscriptionTier.free,
  });

  final String id;

  /// Единственный идентификатор входа: пароля нет, вход по коду из письма.
  final String email;

  final String? fullName;
  final SubscriptionTier subscription;
}

/// Тариф подписки. Определяет приоритет обслуживания и семейный доступ.
