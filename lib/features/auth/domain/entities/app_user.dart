import '../../../../shared/models/subscription_tier.dart';

/// Пользователь MedIx.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.iin,
    this.fullName,
    this.subscription = SubscriptionTier.free,
  });

  final String id;
  final String email;

  /// ИИН РК. Может отсутствовать, если профиль ещё не верифицирован.
  final String? iin;
  final String? fullName;
  final SubscriptionTier subscription;
}

/// Тариф подписки. Определяет приоритет обслуживания и семейный доступ.
