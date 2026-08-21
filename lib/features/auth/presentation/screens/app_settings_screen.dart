import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/app_language.dart';
import '../widgets/consent_row.dart';
import '../widgets/registration_step_layout.dart';

/// Шаг 4 регистрации — язык интерфейса и согласие на рассылки.
///
/// Свёрстан по `design/Язык и пуш увед.png`. Данные и переход дальше —
/// снаружи: экран общий для пациентского и врачебного мастера
/// регистрации (см. `Routes.appSettings`/`Routes.doctorRegisterLanguage`
/// в `app_router.dart`), у каждого свой контроллер состояния.
class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({
    super.key,
    required this.language,
    required this.pushConsent,
    required this.onLanguageSelected,
    required this.onPushConsentChanged,
    required this.onNext,
  });

  final AppLanguage? language;
  final bool pushConsent;
  final ValueChanged<AppLanguage> onLanguageSelected;
  final ValueChanged<bool> onPushConsentChanged;

  /// `null` — кнопка недоступна (язык ещё не выбран).
  final VoidCallback? onNext;

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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RegistrationStepLayout(
      progress: RegistrationProgress.appSettings,
      barToTitle: _barToTitle,
      title: l10n.appSettingsTitle,
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
                for (final option in AppLanguage.values) ...[
                  if (option != AppLanguage.values.first)
                    const SizedBox(height: _rowGap),
                  _LanguageRow(
                    language: option,
                    selected: language == option,
                    onTap: () => onLanguageSelected(option),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: _cardToConsent),
        ConsentRow(
          value: pushConsent,
          onChanged: onPushConsentChanged,
          text: l10n.pushConsentText,
        ),
        const SizedBox(height: _consentToButton),
        RegistrationNextButton(
          child: PrimaryButton(
            label: l10n.nextButtonLabel,
            trailingIcon: Icons.arrow_forward,
            // Согласие на рассылки не блокирует переход — блокирует только
            // невыбранный язык.
            onPressed: onNext,
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
