import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/profile_metrics.dart';

/// «Свяжитесь с нами» — свёрстан по `design/Свяжитесь с нами.png`.
///
/// Контакты пока зашиты в код: отдельного эндпоинта под них нет, а меняются
/// они раз в год. Когда появится — переедут в репозиторий.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const List<String> supportPhones = [
    '+7 700 000 00 00',
    '+7 700 000 00 00',
  ];

  static const String supportEmail = 'info.medix.clients@gmail.com';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              ScreenTopBar(
                title: AppLocalizations.of(context)!.contactUsTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 74),
              const _Section(child: _PhonesCard()),
              const SizedBox(height: ProfileMetrics.settingsGap),
              const _Section(child: _MailCard()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

/// Синяя карточка: номера поддержки прижаты к низу.
class _PhonesCard extends StatelessWidget {
  const _PhonesCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.contactPhonesHeight,
      child: AppCard(
        color: AppColors.primaryBright,
        borderRadius: ProfileMetrics.allRadius,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              AppLocalizations.of(context)!.supportPhonesTitle,
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 12),
            for (final phone in ContactScreen.supportPhones) ...[
              Text(
                phone,
                style: AppTypography.h2.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              if (phone != ContactScreen.supportPhones.last)
                const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

/// Голубая карточка: почта и соцсети.
class _MailCard extends StatelessWidget {
  const _MailCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: ProfileMetrics.contactMailHeight,
      child: AppCard(
        color: AppColors.accentSofter,
        borderRadius: ProfileMetrics.allRadius,
        padding: const EdgeInsets.fromLTRB(14, 42, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.emailSectionTitle, style: AppTypography.tileSubtitle),
            const SizedBox(height: 14),
            Text(
              ContactScreen.supportEmail,
              style: AppTypography.titleMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(l10n.socialNetworksTitle, style: AppTypography.tileSubtitle),
            const SizedBox(height: 10),
            const Row(
              children: [
                AppIcon(
                  icon: MedixIcon.instagram,
                  size: ProfileMetrics.socialSize,
                  color: AppColors.primary,
                ),
                SizedBox(width: ProfileMetrics.socialGap),
                AppIcon(
                  icon: MedixIcon.whatsapp,
                  size: ProfileMetrics.socialSize,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ProfileMetrics.screenH),
      child: child,
    );
  }
}
