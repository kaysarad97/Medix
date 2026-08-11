import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/app_settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/login_verify_screen.dart';
import '../../features/auth/presentation/screens/personal_data_screen.dart';
import '../../features/auth/presentation/screens/policy_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/calls/presentation/screens/call_screen.dart';
import '../../features/chats/presentation/screens/chats_list_screen.dart';
import '../../features/chats/presentation/screens/doctor_chat_screen.dart';
import '../../features/family_access/presentation/screens/family_list_screen.dart';
import '../../features/family_access/presentation/screens/family_member_form_screen.dart';
import '../../features/family_access/presentation/screens/family_member_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lab_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/lab_services/presentation/screens/lab_offers_screen.dart';
import '../../features/lab_services/presentation/screens/lab_services_screen.dart';
import '../../features/map_search/presentation/screens/map_search_screen.dart';
import '../../features/profile/presentation/screens/avatar_picker_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/medical_card_form_screen.dart';
import '../../features/profile/presentation/screens/medical_card_screen.dart';
import '../../features/profile/presentation/screens/procedures_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/data/repositories/subscriptions_repository.dart';
import '../../features/subscriptions/presentation/screens/card_form_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_method_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_result_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_screen.dart';
import '../../features/telemedicine/presentation/screens/appointment_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_profile_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_search_results_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_search_screen.dart';
import 'app_shell.dart';
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
        path: Routes.loginVerify,
        builder: (context, state) => const LoginVerifyScreen(),
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
      // Нижняя навигация: Домой/Карта/Чаты/Профиль — общий плавающий
      // таб-бар в AppShell, у каждой ветки свой стек и своя история.
      // Порядок веток совпадает с порядком вкладок в BottomNavBar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.mapSearch,
                builder: (context, state) => const MapSearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.chats,
                builder: (context, state) => const ChatsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const MedicalCardScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.chatbot,
        builder: (context, state) => const ChatbotScreen(),
      ),
      GoRoute(
        path: Routes.labServices,
        builder: (context, state) => const LabServicesScreen(),
      ),
      GoRoute(
        path: Routes.labOffers,
        builder: (context, state) => const LabOffersScreen(),
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
        path: Routes.doctorSearch,
        builder: (context, state) => const DoctorSearchScreen(),
      ),
      GoRoute(
        path: Routes.doctorSearchResults,
        builder: (context, state) => DoctorSearchResultsScreen(
          query: state.uri.queryParameters['q'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.appointment,
        builder: (context, state) =>
            AppointmentScreen(appointmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.call,
        builder: (context, state) =>
            CallScreen(appointmentId: state.pathParameters['id']!),
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
        path: Routes.medicalCardForm,
        builder: (context, state) => const MedicalCardFormScreen(),
      ),
      GoRoute(
        path: Routes.procedures,
        builder: (context, state) => const ProceduresScreen(),
      ),
      GoRoute(
        path: Routes.family,
        builder: (context, state) => const FamilyListScreen(),
      ),
      // Раньше карточки члена семьи: иначе `:id` поймает «new» как
      // идентификатор и вместо формы откроется пустая карточка.
      GoRoute(
        path: Routes.familyMemberNew,
        builder: (context, state) => const FamilyMemberFormScreen(),
      ),
      GoRoute(
        path: Routes.familyMember,
        builder: (context, state) =>
            FamilyMemberScreen(memberId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.familyMemberEdit,
        builder: (context, state) =>
            FamilyMemberFormScreen(memberId: state.pathParameters['id']!),
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
        builder: (context, state) => ProfileSettingsScreen(
          onChangeAvatar: () => context.push(Routes.avatarPicker),
        ),
      ),
      GoRoute(
        path: Routes.avatarPicker,
        builder: (context, state) => const AvatarPickerScreen(),
      ),
      GoRoute(
        path: Routes.contacts,
        builder: (context, state) => const ContactScreen(),
      ),
    ],
  );
});
