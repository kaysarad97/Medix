import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../data/legal/privacy_policy_draft.dart';
import '../providers/registration_controller.dart';
import '../widgets/consent_row.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 5 регистрации — политика конфиденциальности.
///
/// Свёрстан по `design/Политика конф и обработка инф.png`. Структура здесь
/// своя, [RegistrationStepLayout] не подходит: заголовок стоит НАД
/// прогресс-баром, а не под ним.
///
/// Макет нарисован высотой 1118 — это не размер какого-либо устройства,
/// дизайнер просто вытянул страницу. Поэтому карточка с текстом тянется
/// по доступной высоте и прокручивается внутри себя, а страница целиком не
/// скроллится: вложенная прокрутка внутри прокрутки неудобна на телефоне.
class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  /// Заголовок 111…154 при безопасной зоне 62.
  static const double _titleTop = 49;

  /// Заголовок 111…154 → бар 187.
  static const double _titleToBar = 33;

  /// Бар 187…196 → карточка 235.
  static const double _barToCard = 38;

  /// Карточка → блок согласия.
  static const double _cardToConsent = 36;

  /// Согласие → кнопка.
  static const double _consentToButton = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);

    return AppScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: _titleTop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Text(
                'Политика Конфиденциальности и Условия '
                'Обработки Персональных Данных',
                textAlign: TextAlign.center,
                style: AppTypography.policyTitle,
              ),
            ),
            const SizedBox(height: _titleToBar),
            const StepProgressBar(progress: RegistrationProgress.policy),
            const SizedBox(height: _barToCard),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: const _PolicyTextCard(),
              ),
            ),
            const SizedBox(height: _cardToConsent),
            ConsentRow(
              value: state.policyAccepted,
              onChanged: controller.setPolicyAccepted,
              text:
                  'Я даю согласие на обработку моих персональных данных, '
                  'включая данные о состоянии здоровья, на условиях, '
                  'изложенных в Политике конфиденциальности.',
            ),
            const SizedBox(height: _consentToButton),
            RegistrationNextButton(
              child: PrimaryButton(
                label: 'Далее',
                trailingIcon: Icons.arrow_forward,
                // Без согласия дальше нельзя: обрабатывать медицинские
                // данные без него противозаконно.
                onPressed: state.policyAccepted
                    ? () {
                        if (controller.submitPolicy()) {
                          // Регистрация завершена — стек мастера сбрасываем.
                          context.go(Routes.home);
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _PolicyTextCard extends StatelessWidget {
  const _PolicyTextCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(13, 17, 13, 17),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // На месте красной пометки дизайнера «СОГЛАСОВАТЬСЯ С ЮРИСТОМ
            // И ЗАМЕНИТЬ ТЕКСТ». Убрать вместе с черновиком.
            Text(
              PrivacyPolicyDraft.pendingApprovalNotice,
              style: AppTypography.consent.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(PrivacyPolicyDraft.body, style: AppTypography.legalBody),
            const SizedBox(height: AppSpacing.md),
            for (final section in PrivacyPolicyDraft.sections) ...[
              Text(section, style: AppTypography.legalBody),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
