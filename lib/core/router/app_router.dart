import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/doctor_registration_controller.dart';
import '../../features/auth/presentation/providers/registration_controller.dart';
import '../../features/auth/presentation/screens/app_settings_screen.dart';
import '../../features/auth/presentation/screens/doctor_register_screen.dart';
import '../../features/auth/presentation/screens/doctor_register_verify_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/login_verify_screen.dart';
import '../../features/auth/presentation/screens/personal_data_screen.dart';
import '../../features/auth/presentation/screens/policy_screen.dart';
import '../../features/auth/presentation/screens/register_role_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/verify_code_screen.dart';
import '../../features/calls/presentation/screens/call_screen.dart';
import '../../features/chats/presentation/screens/chats_list_screen.dart';
import '../../features/chats/presentation/screens/doctor_chat_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_chats_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_call_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_calendar_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_certificates_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_home_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_chatbot_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_profile_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_profile_settings_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_settings_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_work_schedule_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_admin_answer_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_admin_request_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_admin_requests_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_analytics_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_history_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_past_appointment_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_patient_appointment_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_patient_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_patient_chat_screen.dart';
import '../../features/doctor_cabinet/presentation/screens/doctor_reviews_screen.dart';
import '../../features/family_access/presentation/screens/family_list_screen.dart';
import '../../features/family_access/presentation/screens/family_member_form_screen.dart';
import '../../features/family_access/presentation/screens/family_member_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/lab_chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/lab_services/presentation/screens/lab_offers_screen.dart';
import '../../features/lab_services/presentation/screens/lab_referral_screen.dart';
import '../../features/lab_services/presentation/screens/lab_results_screen.dart';
import '../../features/lab_services/presentation/screens/lab_services_screen.dart';
import '../../features/map_search/presentation/screens/map_search_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/avatar_picker_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/medical_card_form_screen.dart';
import '../../features/profile/presentation/screens/medical_card_screen.dart';
import '../../features/profile/presentation/screens/measurement_history_screen.dart';
import '../../features/profile/domain/entities/medical_card.dart';
import '../../features/profile/presentation/screens/procedures_screen.dart';
import '../../features/profile/presentation/screens/profile_settings_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/subscriptions/data/repositories/subscriptions_repository.dart';
import '../../features/subscriptions/presentation/screens/card_form_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_method_screen.dart';
import '../../features/subscriptions/presentation/screens/payment_result_screen.dart';
import '../../features/subscriptions/presentation/screens/subscription_screen.dart';
import '../../features/subscriptions/presentation/screens/cancel_subscription_screen.dart';
import '../../features/telemedicine/presentation/screens/appointment_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_profile_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_search_results_screen.dart';
import '../../features/telemedicine/presentation/screens/doctor_search_screen.dart';
import '../../features/telemedicine/presentation/screens/leave_review_screen.dart';
import '../../features/telemedicine/presentation/screens/waitlist_screen.dart';
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
        path: Routes.registerRoleChoice,
        builder: (context, state) => const RegisterRoleScreen(),
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
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final regState = ref.watch(registrationControllerProvider);
            final controller = ref.read(
              registrationControllerProvider.notifier,
            );
            return AppSettingsScreen(
              language: regState.language,
              pushConsent: regState.pushConsent,
              onLanguageSelected: controller.setLanguage,
              onPushConsentChanged: controller.setPushConsent,
              onNext: regState.language == null
                  ? null
                  : () {
                      if (controller.submitAppSettings()) {
                        context.push(Routes.policy);
                      }
                    },
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.policy,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final regState = ref.watch(registrationControllerProvider);
            final controller = ref.read(
              registrationControllerProvider.notifier,
            );
            return PolicyScreen(
              policyAccepted: regState.policyAccepted,
              onPolicyAcceptedChanged: controller.setPolicyAccepted,
              onNext: regState.policyAccepted
                  ? () {
                      if (controller.submitPolicy()) {
                        // Регистрация завершена — стек мастера сбрасываем.
                        context.go(Routes.home);
                      }
                    }
                  : null,
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.doctorRegister,
        builder: (context, state) => const DoctorRegisterScreen(),
      ),
      GoRoute(
        path: Routes.doctorRegisterVerify,
        builder: (context, state) => const DoctorRegisterVerifyScreen(),
      ),
      GoRoute(
        path: Routes.doctorRegisterCard,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            return CardFormScreen(
              // Задел на будущую монетизацию, не оплата — своего
              // эндпоинта под сохранение карты врача ещё нет (см.
              // HANDOFF). Подтверждённые данные никуда не уходят,
              // мастер просто идёт дальше.
              onSubmit: (_) async => PaymentOutcome.success,
              onResult: (_) => context.push(Routes.doctorRegisterLanguage),
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.doctorRegisterLanguage,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final regState = ref.watch(doctorRegistrationControllerProvider);
            final controller = ref.read(
              doctorRegistrationControllerProvider.notifier,
            );
            return AppSettingsScreen(
              language: regState.language,
              pushConsent: regState.pushConsent,
              onLanguageSelected: controller.setLanguage,
              onPushConsentChanged: controller.setPushConsent,
              onNext: regState.language == null
                  ? null
                  : () {
                      if (controller.submitAppSettings()) {
                        context.push(Routes.doctorRegisterPolicy);
                      }
                    },
            );
          },
        ),
      ),
      GoRoute(
        path: Routes.doctorRegisterPolicy,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final regState = ref.watch(doctorRegistrationControllerProvider);
            final controller = ref.read(
              doctorRegistrationControllerProvider.notifier,
            );
            return PolicyScreen(
              policyAccepted: regState.policyAccepted,
              onPolicyAcceptedChanged: controller.setPolicyAccepted,
              onNext: regState.policyAccepted
                  ? () {
                      if (controller.submitPolicy()) {
                        // Регистрация завершена — стек мастера сбрасываем.
                        context.go(Routes.doctorHome);
                      }
                    }
                  : null,
            );
          },
        ),
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
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
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
        path: Routes.labReferral,
        builder: (context, state) => const LabReferralScreen(),
      ),
      GoRoute(
        path: Routes.labResults,
        builder: (context, state) => LabResultsScreen(
          familyMemberId: state.uri.queryParameters['family_member_id'],
        ),
      ),
      GoRoute(
        path: Routes.labOffers,
        builder: (context, state) =>
            LabOffersScreen(referralId: state.uri.queryParameters['referral']),
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
        path: Routes.doctorReview,
        builder: (context, state) =>
            LeaveReviewScreen(doctorId: state.pathParameters['id']!),
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
        path: Routes.doctorHome,
        builder: (context, state) => const DoctorHomeScreen(),
      ),
      GoRoute(
        path: Routes.doctorCalendar,
        builder: (context, state) => const DoctorCalendarScreen(),
      ),
      GoRoute(
        path: Routes.doctorProfile,
        builder: (context, state) => const DoctorOwnProfileScreen(),
      ),
      GoRoute(
        path: Routes.doctorCertificates,
        builder: (context, state) => DoctorCertificatesScreen(
          showUploadRow: state.uri.queryParameters['upload'] == 'true',
        ),
      ),
      GoRoute(
        path: Routes.doctorOwnReviews,
        builder: (context, state) => const DoctorReviewsScreen(),
      ),
      GoRoute(
        path: Routes.doctorHistory,
        builder: (context, state) => const DoctorHistoryScreen(),
      ),
      GoRoute(
        path: Routes.doctorPastAppointment,
        builder: (context, state) => DoctorPastAppointmentScreen(
          appointmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: Routes.doctorAnalytics,
        builder: (context, state) => const DoctorAnalyticsScreen(),
      ),
      GoRoute(
        path: Routes.doctorSettings,
        builder: (context, state) => const DoctorSettingsScreen(),
      ),
      GoRoute(
        path: Routes.doctorProfileSettings,
        builder: (context, state) => const DoctorProfileSettingsScreen(),
      ),
      GoRoute(
        path: Routes.doctorBankDetails,
        builder: (context, state) => CardFormScreen(
          // Тот же приём, что и в регистрации фрилансера
          // (Routes.doctorRegisterCard): своего эндпоинта сохранения
          // банковских данных врача нет, подтверждённые данные никуда не
          // уходят.
          onSubmit: (_) async => PaymentOutcome.success,
          onResult: (_) => context.pop(),
        ),
      ),
      GoRoute(
        path: Routes.doctorChatbot,
        builder: (context, state) => const DoctorChatbotScreen(),
      ),
      GoRoute(
        path: Routes.doctorWorkSchedule,
        builder: (context, state) => const DoctorWorkScheduleScreen(),
      ),
      GoRoute(
        path: Routes.doctorAdminRequests,
        builder: (context, state) => const DoctorAdminRequestsScreen(),
      ),
      GoRoute(
        path: Routes.doctorAdminNewRequest,
        builder: (context, state) => const DoctorAdminRequestScreen(),
      ),
      GoRoute(
        path: Routes.doctorAdminRequest,
        builder: (context, state) =>
            DoctorAdminAnswerScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.doctorChats,
        builder: (context, state) => const DoctorChatsScreen(),
      ),
      GoRoute(
        path: Routes.doctorPatientChat,
        builder: (context, state) =>
            DoctorPatientChatScreen(threadId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.doctorPatient,
        builder: (context, state) =>
            DoctorPatientScreen(patientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.doctorCall,
        builder: (context, state) =>
            DoctorCallScreen(patientId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.doctorPatientAppointment,
        builder: (context, state) => DoctorPatientAppointmentScreen(
          patientId: state.pathParameters['id']!,
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
        path: Routes.cancelSubscription,
        builder: (context, state) => const CancelSubscriptionScreen(),
      ),
      GoRoute(
        path: Routes.waitlist,
        builder: (context, state) => WaitlistScreen(
          onAppointmentClaimed: (appointment) =>
              context.push(Routes.appointmentOf(appointment.id)),
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
          onCancelSubscription: () => context.push(Routes.cancelSubscription),
        ),
      ),
      GoRoute(
        path: Routes.heightHistory,
        builder: (context, state) =>
            const MeasurementHistoryScreen(kind: MeasurementKind.height),
      ),
      GoRoute(
        path: Routes.weightHistory,
        builder: (context, state) =>
            const MeasurementHistoryScreen(kind: MeasurementKind.weight),
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
