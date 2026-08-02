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

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSession(
      user: AppUser(
        id: user['id'] as String,
        email: user['email'] as String,
        iin: user['iin'] as String?,
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
