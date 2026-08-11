import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/family_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/family_providers.dart';

/// «Моя Семья» — список близких и вход в добавление нового.
///
/// МАКЕТА НЕТ. В `design/` есть только карточки уже добавленных членов семьи
/// («Моя Семья Ребенок.png», «Моя Семья Старшие.png»), а экрана со списком и
/// формы добавления дизайнер не присылал — вопрос ему задан. Экран собран из
/// готовых частей: та же карточка [FamilyCard], что на «Ваша Мед-Карта», и
/// обычная кнопка. Придёт макет — менять придётся вёрстку, а не работу с
/// данными.
class FamilyListScreen extends ConsumerWidget {
  const FamilyListScreen({super.key});

  /// Как на остальных внутренних экранах профиля.
  static const double _topBarTop = 36;
  static const double _topBarToCard = 26;
  static const double _cardToButton = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider).value ?? const [];
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topBarTop),
              ScreenTopBar(
                title: l10n.familyScreenTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: _topBarToCard),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: members.isEmpty
                    ? Text(
                        l10n.familyEmptyHint,
                        style: AppTypography.captionMuted,
                        textAlign: TextAlign.center,
                      )
                    : FamilyCard(
                        members: members,
                        title: l10n.familyScreenTitle,
                        rowStyle: FamilyRowStyle.entry,
                        onMemberTap: (member) =>
                            context.push(Routes.familyMemberOf(member.id)),
                      ),
              ),
              const SizedBox(height: _cardToButton),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: PrimaryButton(
                  label: l10n.familyAddButton,
                  // Значок временный: своей иконки «плюс» дизайнер не
                  // присылал, а заводить её в MedixIcons без исходника
                  // нельзя — см. icon_chip.dart.
                  trailingIcon: Icons.add,
                  onPressed: () => context.push(Routes.familyMemberNew),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
