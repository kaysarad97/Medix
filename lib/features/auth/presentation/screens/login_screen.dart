import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/login_controller.dart';
import '../widgets/social_auth_row.dart';

/// Экран логина.
///
/// Свёрстан по `design/Логин Старт.png`. Макет 440×956 = логические точки
/// iPhone 16 Pro Max, поэтому вертикальные отступы ниже — прямые замеры,
/// а не подобранные значения. Каждая константа помечена позицией в макете.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  /// Верх строки заголовка — 172 при безопасной зоне 62.
  static const double _titleTop = 110;

  /// Заголовок 172…215 → карточка 303.
  static const double _titleToCard = 88;

  /// Карточка 303…537 → «или авторизоваться через» 566.
  static const double _cardToSocial = 28;

  /// Блок соцсетей 566…616 → кнопка 652.
  static const double _socialToButton = 29;

  /// Кнопка 652…722 → ссылка 765.
  static const double _buttonToLink = 35;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(loginControllerProvider.notifier);
    final state = ref.watch(loginControllerProvider);

    ref.listen(loginControllerProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        context.go(Routes.home);
        return;
      }

      final error = next.formError;
      if (error != null && error != previous?.formError) {
        showFormErrorSnackBar(context, error);
        controller.formErrorShown();
      }
    });

    return AppScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _titleTop),
              Text(
                'Логин',
                textAlign: TextAlign.center,
                style: AppTypography.h1,
              ),
              const SizedBox(height: _titleToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.formCardH,
                ),
                child: _CredentialsCard(
                  identifierController: _identifierController,
                  passwordController: _passwordController,
                  passwordFocus: _passwordFocus,
                  state: state,
                  onIdentifierChanged: controller.identifierChanged,
                  onPasswordChanged: controller.passwordChanged,
                  onSubmit: controller.submit,
                ),
              ),
              const SizedBox(height: _cardToSocial),
              SocialAuthRow(
                onGooglePressed: () {
                  // TODO(auth): подключить Google Sign-In, когда будет
                  // готов эндпоинт /auth/google на бэкенде.
                },
              ),
              const SizedBox(height: _socialToButton),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: 'Войти',
                  size: PrimaryButtonSize.large,
                  color: AppColors.primary,
                  isLoading: state.isSubmitting,
                  onPressed: state.canSubmit ? controller.submit : null,
                ),
              ),
              const SizedBox(height: _buttonToLink),
              Center(
                child: GestureDetector(
                  onTap: () => context.push(Routes.register),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      'или создать профиль',
                      style: AppTypography.link,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialsCard extends StatelessWidget {
  const _CredentialsCard({
    required this.identifierController,
    required this.passwordController,
    required this.passwordFocus,
    required this.state,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
  });

  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final FocusNode passwordFocus;
  final LoginState state;
  final ValueChanged<String> onIdentifierChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;

  /// Внутренние поля карточки: слева/справа 13, сверху 18, снизу 12.
  static const EdgeInsets _cardPadding = EdgeInsets.fromLTRB(13, 18, 13, 12);

  /// Низ первого поля (415) → верх подписи «Пароль:» (431).
  static const double _fieldToLabel = 16;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: _cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Ваш E-mail или ИИН:',
            controller: identifierController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            errorText: state.identifierError,
            onChanged: onIdentifierChanged,
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
          const SizedBox(height: _fieldToLabel),
          AppTextField(
            label: 'Пароль:',
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            errorText: state.passwordError,
            onChanged: onPasswordChanged,
            onSubmitted: (_) => onSubmit(),
            // В `Логин Старт.png` кнопки «показать пароль» нет, хотя на
            // `Создайте профиль.png` она есть. Оставлено как в макете
            // логина — AppTextField поддерживает suffix, включается одной
            // строкой, если дизайн решит добавить.
          ),
        ],
      ),
    );
  }
}
