import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/app_settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/personal_data_screen.dart';
import '../../features/auth/presentation/screens/policy_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/medical_card_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/telemedicine/presentation/screens/appointment_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_profile_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Пока нет восстановления сессии из secure storage — старт с логина.
    // TODO(auth): redirect на Routes.home, если в хранилище есть валидный
    // refresh-токен.
    initialLocation: Routes.login,
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.personalData,
        builder: (context, state) => const PersonalDataScreen(),
      ),
      GoRoute(
        path: Routes.verifyCode,
        builder: (context, state) => const VerifyCodeScreen(),
      ),
      GoRoute(
        path: Routes.appSettings,
        builder: (context, state) => const AppSettingsScreen(),
      ),
      GoRoute(
        path: Routes.policy,
        builder: (context, state) => const PolicyScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.doctor,
        builder: (context, state) =>
            DoctorProfileScreen(doctorId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.appointment,
        builder: (context, state) =>
            AppointmentScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const MedicalCardScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => SettingsScreen(
          onOpenProfileSettings: () => context.push(Routes.profileSettings),
          onOpenContacts: () => context.push(Routes.contacts),
        ),
      ),
      GoRoute(
        path: Routes.profileSettings,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: Routes.contacts,
        builder: (context, state) => const ContactScreen(),
      ),
    ],
  );
});
