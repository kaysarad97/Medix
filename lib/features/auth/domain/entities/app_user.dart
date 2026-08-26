import '../../../../shared/models/subscription_tier.dart';

enum AppUserRole {
  patient,
  doctor;

  static AppUserRole fromCode(Object? value) =>
      value == 'doctor' ? doctor : patient;
}

/// Пользователь MedIx.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.role = AppUserRole.patient,
    this.fullName,
    this.subscription = SubscriptionTier.free,
  });

  final String id;

  /// Единственный идентификатор входа: пароля нет, вход по коду из письма.
  final String email;

  final AppUserRole role;

  final String? fullName;
  final SubscriptionTier subscription;
}

/// Тариф подписки. Определяет приоритет обслуживания и семейный доступ.
