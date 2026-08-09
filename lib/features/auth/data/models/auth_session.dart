import '../../../../shared/models/subscription_tier.dart';
import '../../domain/entities/app_user.dart';

/// Результат успешной авторизации.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AppUser user;
  final String accessToken;
  final String refreshToken;

  /// Разбирает ответ подтверждения кода.
  ///
  /// Бэкенд кладёт в тот же объект `token_type` и `is_new_user` — они здесь
  /// не нужны: тип всегда `bearer`, а «новый ли пользователь» решает экран,
  /// с которого пришли.
  ///
  /// Тариф подписки бэкенд пока не отдаёт (эндпоинты подписок — заглушки),
  /// поэтому до их появления у всех будет бесплатный.
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      user: AppUser(
        id: user['id'] as String,
        email: user['email'] as String,
        fullName: user['full_name'] as String?,
        subscription: SubscriptionTier.values.firstWhere(
          (t) => t.name == user['subscription'],
          orElse: () => SubscriptionTier.free,
        ),
      ),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }
}
