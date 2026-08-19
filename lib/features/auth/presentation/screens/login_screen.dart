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
import '../../../../l10n/app_localizations.dart';
import '../providers/login_controller.dart';

/// Экран входа — шаг 1: почта.
///
/// Свёрстан по `design/Логин Старт.png`. Макет 440×956 = логические точки
/// iPhone 16 Pro Max, поэтому вертикальные отступы ниже — прямые замеры,
/// а не подобранные значения. Каждая константа помечена позицией в макете.
///
/// Отличие от макета: поля пароля нет — бэкенд паролей не хранит, вход идёт
/// по одноразовому коду из письма. Карточка из-за этого ниже, чем нарисовано.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();

  /// Верх строки заголовка — 172 при безопасной зоне 62.
  static const double _titleTop = 110;

  /// Заголовок 172…215 → карточка 303.
  static const double _titleToCard = 88;

  /// Карточка → кнопка. В макете между ними стоял блок «или авторизоваться
  /// через» с иконкой Google (566…616), и разрыв делился на 28 + 50 + 29.
  /// Вход через Google исключён из объёма MVP решением от 20 августа 2026 —
  /// сам блок снят, а зазор взят обычным межсекционным, а не суммой трёх:
  /// иначе посреди экрана осталась бы пустая полоса в треть высоты карточки.
  static const double _cardToButton = 44;

  /// Кнопка 652…722 → ссылка 765.
  static const double _buttonToLink = 35;

  /// Внутренние поля карточки: слева/справа 13, сверху 18, снизу 12.
  static const EdgeInsets _cardPadding = EdgeInsets.fromLTRB(13, 18, 13, 12);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(loginControllerProvider.notifier);
    final state = ref.watch(loginControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(loginControllerProvider, (previous, next) {
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
                l10n.loginTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h1,
              ),
              const SizedBox(height: _titleToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.formCardH,
                ),
                child: AppCard(
                  padding: _cardPadding,
                  child: AppTextField(
                    label: l10n.emailLabel,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    errorText: state.emailError,
                    onChanged: controller.emailChanged,
                    onSubmitted: (_) => _next(),
                  ),
                ),
              ),
              const SizedBox(height: _cardToButton),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: l10n.sendCodeButtonLabel,
                  size: PrimaryButtonSize.large,
                  color: AppColors.primary,
                  isLoading: state.isSubmitting,
                  onPressed: state.canSubmitEmail ? _next : null,
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
                      l10n.createProfileLink,
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

  Future<void> _next() async {
    final ok = await ref.read(loginControllerProvider.notifier).submitEmail();
    if (ok && mounted) context.push(Routes.loginVerify);
  }
}
