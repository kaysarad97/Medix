import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/family_relation_labels.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/form_error_snack_bar.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/family_member.dart';
import '../../../profile/presentation/widgets/analyses_card.dart';
import '../../../profile/presentation/widgets/medical_card_summary.dart';
import '../../../profile/presentation/widgets/my_doctors_card.dart';
import '../../../profile/presentation/widgets/profile_metrics.dart';
import '../providers/family_providers.dart';

/// Карточка члена семьи — «Профиль ребёнка» и «Профиль родителя».
///
/// Свёрстан по `design/Моя Семья Ребенок.png` и `design/Моя Семья
/// Старшие.png` (440×1673): один экран на оба макета, различие только в
/// заголовке, подписях карточек (собираются здесь по `member.relation`,
/// см. ниже) и аватаре. Верхняя строка проще, чем на «Ваша Мед-Карта»: без
/// шестерёнки настроек и без значка подписки — у члена семьи нет ни того,
/// ни другого.
///
/// Внизу — кнопка «Удалить профиль» из обновлённых макетов. До них удаление
/// жило в форме правки красной надписью под кнопкой «Далее»: своего макета
/// у него не было, и оно стояло там, где его удалось приткнуть. Теперь
/// удаление там, где его нарисовал дизайнер, и в форме его больше нет.
///
/// Карточки «Мед-карта», «Врачи…» и «Анализы…» — те же виджеты, что и на
/// экране пользователя (`MedicalCardSummary`, `MyDoctorsCard`,
/// `AnalysesCard`), с другими подписями и данными.
class FamilyMemberScreen extends ConsumerWidget {
  const FamilyMemberScreen({super.key, required this.memberId, this.now});

  final String memberId;

  /// Подменяется в тестах: возраст в карточке считается от сегодняшнего дня.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(familyMemberProvider(memberId)).value;
    final doctors =
        ref.watch(familyDoctorsProvider(memberId)).value ?? const [];
    final analyses =
        ref.watch(familyAnalysesProvider(memberId)).value ?? const [];
    final filter = ref.watch(familyAnalysesFilterProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: member == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    ScreenTopBar(
                      title: member.relation.screenTitle(l10n),
                      onBack: () => Navigator.of(context).maybePop(),
                      // Карандаш из Material: своей иконки правки дизайнер
                      // не присылал, а заводить её в MedixIcons без
                      // исходника нельзя — см. icon_chip.dart.
                      trailing: GestureDetector(
                        onTap: () =>
                            context.push(Routes.familyMemberEditOf(memberId)),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 22,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.topBarToHeader),
                    _MemberHeader(member: member),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MedicalCardSummary(
                        topFieldValue: member.relation.name(l10n),
                        topFieldPlaceholder: l10n.relationshipPlaceholder,
                        heightLabel: member.heightLabel,
                        weightLabel: member.weightLabel,
                        ageLabel: member.ageLabel(now ?? DateTime.now()),
                        registrationAddress: member.registrationAddress,
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    _Section(
                      child: MyDoctorsCard(
                        doctors: doctors,
                        title: member.relation.doctorsCardTitle(l10n),
                      ),
                    ),
                    const SizedBox(height: ProfileMetrics.cardGap),
                    if (analyses.isNotEmpty) ...[
                      _Section(
                        child: AnalysesCard(
                          analyses: analyses,
                          filter: filter,
                          // У всех, кроме ребёнка, заголовок с именем: он
                          // одинаково годится и родителю, и супругу, и брату.
                          title: member.relation.isChild
                              ? l10n.familyAnalysesCardTitleChild
                              : l10n.familyAnalysesCardTitleSenior(
                                  member.fullName,
                                ),
                          onFilterChanged: ref
                              .read(familyAnalysesFilterProvider.notifier)
                              .select,
                        ),
                      ),
                      const SizedBox(height: ProfileMetrics.cardGap),
                    ],
                    _Section(child: _DeleteProfileButton(memberId: memberId)),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Шапка: аватар, имя, пол и дата рождения. В отличие от `ProfileHeader` —
/// без значка подписки: она привязана к аккаунту, а не к члену семьи.
class _MemberHeader extends StatelessWidget {
  const _MemberHeader({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(left: ProfileMetrics.avatarLeft),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            asset: member.avatarAsset,
            size: ProfileMetrics.avatarSize,
            borderRadius: BorderRadius.circular(ProfileMetrics.avatarRadius),
          ),
          const SizedBox(width: ProfileMetrics.avatarToInfo),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(member.firstName, style: AppTypography.profileName),
                Text(member.lastName, style: AppTypography.profileName),
                const SizedBox(height: ProfileMetrics.nameToMeta),
                Row(
                  children: [
                    Expanded(
                      child: _MetaColumn(
                        value: member.genderLabel,
                        label: l10n.genderLabel,
                      ),
                    ),
                    Expanded(
                      child: _MetaColumn(
                        value: member.birthDateLabel,
                        label: l10n.birthDateLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: ProfileMetrics.screenH),
        ],
      ),
    );
  }
}

/// Кнопка «Удалить профиль» под карточками.
///
/// Замеры по `design/Моя Семья Ребенок.png` (440×1673): кнопка x 21…419
/// (те же поля, что у карточек) и y 1500…1556 через 31 после карточки
/// анализов — тот же шаг, что между карточками. Внутри белая подложка
/// значка 48×38 на 13 от левого края, до надписи 20.
///
/// Подтверждение спрашивается диалогом, хотя в макете его нет: удаление
/// необратимо и на сервере (`DELETE /family-members/{id}`), а промахнуться
/// по кнопке во всю ширину экрана легко.
class _DeleteProfileButton extends ConsumerStatefulWidget {
  const _DeleteProfileButton({required this.memberId});

  final String memberId;

  @override
  ConsumerState<_DeleteProfileButton> createState() =>
      _DeleteProfileButtonState();
}

class _DeleteProfileButtonState extends ConsumerState<_DeleteProfileButton> {
  static const double _height = 56;
  static const Size _chipSize = Size(48, 38);
  static const double _chipLeft = 13;
  static const double _chipToLabel = 20;
  static const double _glyphSize = 22;

  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: _height,
      child: Material(
        color: AppColors.accent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _isDeleting ? null : _confirmDelete,
          child: Row(
            children: [
              const SizedBox(width: _chipLeft),
              SizedBox.fromSize(
                size: _chipSize,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: AppRadius.allPill,
                  ),
                  child: Center(
                    child: _isDeleting
                        ? const SizedBox(
                            width: _glyphSize,
                            height: _glyphSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.accent,
                            ),
                          )
                        // Корзины в экспорте дизайнера нет — как и карандаша
                        // правки выше, берём ближайшую из Material.
                        : const Icon(
                            Icons.delete_forever_outlined,
                            size: _glyphSize,
                            color: AppColors.brandIndigo,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: _chipToLabel),
              Text(l10n.familyDeleteButton, style: AppTypography.buttonSm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.familyDeleteConfirmTitle),
        content: Text(l10n.familyDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.deleteButtonLabel,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(familyRepositoryProvider).remove(widget.memberId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showFormErrorSnackBar(context, e.message);
      return;
    }

    // Список перечитывается после любой правки: обе карточки «Моя Семья» и
    // экран списка читают его же.
    ref.invalidate(familyMembersProvider);
    if (!mounted) return;

    // Карточки больше нет — возвращаемся туда, откуда её открыли: это и
    // список семьи, и «Ваша Мед-Карта», и главная. Закрывать нечего —
    // снимаем ожидание с кнопки, иначе она останется крутиться навсегда;
    // так бывает по прямой ссылке и в тестах.
    if (!await Navigator.of(context).maybePop() && mounted) {
      setState(() => _isDeleting = false);
    }
  }
}

class _MetaColumn extends StatelessWidget {
  const _MetaColumn({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: AppTypography.profileMetaValue),
        const SizedBox(height: ProfileMetrics.metaValueToLabel),
        Text(label, style: AppTypography.profileMetaLabel),
      ],
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
