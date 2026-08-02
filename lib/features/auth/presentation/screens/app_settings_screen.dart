import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../shared/models/app_language.dart';
import '../providers/registration_controller.dart';
import '../widgets/consent_row.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 4 регистрации — язык интерфейса и согласие на рассылки.
///
/// Свёрстан по `design/Язык и пуш увед.png`.
class AppSettingsScreen extends ConsumerWidget {
  const AppSettingsScreen({super.key});

  /// Заголовок здесь стоит выше, чем на других шагах: прописные с 263
  /// против 269–270.
  static const double _barToTitle = 58;

  /// Заголовок 254…341 → карточка 362.
  static const double _titleToCard = 21;

  /// Карточка 362…587 → блок согласия 637.
  static const double _cardToConsent = 50;

  /// Согласие 637…669 → кнопка 716.
  static const double _consentToButton = 47;

  /// Строка языка: высота 57, зазор 15, текст отбит слева на 55.
  static const double _rowHeight = 57;
  static const double _rowGap = 15;
  static const double _rowTextInset = 55;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(registrationControllerProvider.notifier);
    final state = ref.watch(registrationControllerProvider);

    return RegistrationStepLayout(
      progress: RegistrationProgress.appSettings,
      barToTitle: _barToTitle,
      title: 'Настройки приложения',
      children: [
        const SizedBox(height: _titleToCard),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: AppCard(
            // На этом макете карточка чуть светлее (#F7F7F7 против #F3F3F3
            // на логине). Разница в 4 уровня яркости неразличима глазом,
            // отдельный токен ради неё не заводим.
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final language in AppLanguage.values) ...[
                  if (language != AppLanguage.values.first)
                    const SizedBox(height: _rowGap),
                  _LanguageRow(
                    language: language,
                    selected: state.language == language,
                    onTap: () => controller.setLanguage(language),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: _cardToConsent),
        ConsentRow(
          value: state.pushConsent,
          onChanged: controller.setPushConsent,
          text:
              'Я согласен(-на) на получение Push-уведомлений, '
              'СМС-сообщений, и электронных писем',
        ),
        const SizedBox(height: _consentToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: 'Далее',
            trailingIcon: Icons.arrow_forward,
            // Согласие на рассылки не блокирует переход — блокирует только
            // невыбранный язык.
            onPressed: state.language == null
                ? null
                : () {
                    if (controller.submitAppSettings()) {
                      context.push(Routes.policy);
                    }
                  },
          ),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSettingsScreen._rowHeight,
      child: Material(
        // Выбранного состояния в макете нет — все три строки нарисованы
        // одинаково. Подсветку собрали из существующих токенов.
        color: selected ? AppColors.accentSofter : AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              const SizedBox(width: AppSettingsScreen._rowTextInset),
              Text(
                language.label,
                style: selected
                    ? AppTypography.bodyLg.copyWith(
                        color: AppColors.brandIndigo,
                      )
                    : AppTypography.bodyLg.copyWith(
                        color: AppColors.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
