import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/app_settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/personal_data_screen.dart';
import '../../features/auth/presentation/screens/policy_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/chats/presentation/screens/chats_list_screen.dart';
import '../../features/chats/presentation/screens/doctor_chat_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lab_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/medical_card_form_screen.dart';
import '../../features/profile/presentation/screens/medical_card_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/data/repositories/subscriptions_repository.dart';
import '../../features/subscriptions/presentation/screens/card_form_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_method_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_result_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_screen.dart';
import '../../features/telemedicine/presentation/screens/appointment_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_profile_screen.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Стартуем с заставки: она проверяет сохранённую сессию и уводит на
    // главную или на логин. Редирект живёт в самом экране, а не в
    // `GoRouter.redirect`, потому что проверка асинхронная, а redirect
    // синхронный — иначе пришлось бы держать статус сессии в отдельном
    // слушателе и обновлять роутер по нему.
    initialLocation: Routes.splash,
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
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
        path: Routes.chatbot,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: Routes.chats,
        builder: (context, state) => const ChatsListScreen(),
      ),
      GoRoute(
        path: Routes.chat,
        builder: (context, state) =>
            DoctorChatScreen(threadId: state.pathParameters['id']!),
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
        path: Routes.subscription,
        builder: (context, state) => SubscriptionScreen(
          onSelectPlan: (plan) => context.push(Routes.payment),
          onSkip: () => context.go(Routes.home),
        ),
      ),
      GoRoute(
        path: Routes.payment,
        builder: (context, state) => PaymentMethodScreen(
          // Kaspi, Halyk и Apple Pay проводят оплату своим интерфейсом —
          // подключим их SDK, когда появятся договоры с провайдерами.
          onMethodSelected: (method) {
            if (method.needsCardForm) context.push(Routes.cardForm);
          },
          onSavedCards: () => context.push(Routes.cardForm),
        ),
      ),
      GoRoute(
        path: Routes.cardForm,
        builder: (context, state) => CardFormScreen(
          onResult: (outcome) =>
              context.push(Routes.paymentResultOf(outcome.name)),
        ),
      ),
      GoRoute(
        path: Routes.paymentResult,
        builder: (context, state) {
          final failed = state.pathParameters['outcome'] == 'failure';
          return PaymentResultScreen(
            outcome: failed ? PaymentOutcome.failure : PaymentOutcome.success,
            onContinue: () => failed ? context.pop() : context.go(Routes.home),
          );
        },
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const MedicalCardScreen(),
      ),
      GoRoute(
        path: Routes.medicalCardForm,
        builder: (context, state) => const MedicalCardFormScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => SettingsScreen(
          onOpenProfileSettings: () => context.push(Routes.profileSettings),
          onOpenPaymentDetails: () => context.push(Routes.payment),
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
