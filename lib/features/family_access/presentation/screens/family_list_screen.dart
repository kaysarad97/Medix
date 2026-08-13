import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/family_member.dart';
import '../providers/family_providers.dart';

/// «Моя Семья» — плитки профилей близких и карточка добавления.
///
/// Свёрстан по `design/Профили семьи.png` (440×956). Замеры: поля экрана 20,
/// карточка 182×208, между колонками 35, между рядами 21.
class FamilyListScreen extends ConsumerWidget {
  const FamilyListScreen({super.key});

  /// Как на остальных внутренних экранах профиля.
  static const double topBarTop = 36;

  /// Низ верхней строки 132 → верх первой карточки 180.
  static const double topBarToGrid = 48;

  /// Карточки 20…202 и 237…419.
  static const double columnGap = 35;
  static const double rowGap = 21;

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
              const SizedBox(height: topBarTop),
              ScreenTopBar(
                title: l10n.familyScreenTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: topBarToGrid),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                // Ширина карточки считается от экрана, а не берётся из
                // макета: 182 + 35 + 182 не влезает в 393 точки реального
                // телефона, и вторая колонка уехала бы на новую строку.
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - columnGap) / 2;
                    return Wrap(
                      spacing: columnGap,
                      runSpacing: rowGap,
                      children: [
                        for (final member in members)
                          SizedBox(
                            width: cardWidth,
                            child: _ProfileCard(
                              member: member,
                              onTap: () => context.push(
                                Routes.familyMemberOf(member.id),
                              ),
                            ),
                          ),
                        SizedBox(
                          width: cardWidth,
                          child: _AddCard(
                            onTap: () => context.push(Routes.familyMemberNew),
                          ),
                        ),
                      ],
                    );
                  },
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

/// Общие размеры плитки: у карточки профиля и карточки добавления они
/// совпадают до пикселя, разная только заливка.
abstract final class _CardMetrics {
  /// Угол карточки в макете ≈ 18, как у полей и кнопок.
  static const BorderRadius radius = AppRadius.allMd;

  /// Картинка 47…174 при карточке 20…202 — по 27 с боков, 14 сверху.
  static const double sideInset = 27;
  static const double topInset = 14;

  /// Пропорция картинки: 128×144.
  static const double imageAspect = 128 / 144;

  /// Картинка 194…337 → пилюля 351…379 → низ карточки 389.
  static const double imageToPill = 14;
  static const double pillHeight = 29;
  static const double bottomInset = 10;

  /// Пилюля 44…177 при карточке 20…202 — по 24 с боков.
  static const double pillInset = 24;
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.member, required this.onTap});

  final FamilyMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      color: AppColors.surface,
      onTap: onTap,
      image: (borderRadius) => UserAvatar(
        asset: member.avatarAsset,
        size: Size.infinite,
        borderRadius: borderRadius,
      ),
      pill: _Pill(
        label: member.fullName,
        // Шеврон — как на карточках профиля: строка ведёт внутрь.
        trailing: const AppIcon(
          icon: MedixIcon.chevronRight,
          size: 12,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// «Добавить профиль» — та же плитка, но с плюсом вместо лица.
///
/// РАСХОЖДЕНИЕ С МАКЕТОМ, ОСОЗНАННОЕ. В макете эта плитка полупрозрачная:
/// её заливка меняется вместе с фоном, по пикселям выходит белый с альфой
/// около 0,6. Так нельзя: в макете она стоит на синей части фона, а у нас
/// экран прокручивается, и внизу фон белый — полупрозрачная белая плитка на
/// белом исчезает совсем. Взяты сплошные цвета: плашка та же, что у соседей,
/// поле под плюсом — светло-голубое.
class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  /// Окружность плюса в макете 48.
  static const double _plusSize = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _CardShell(
      color: AppColors.surface,
      onTap: onTap,
      image: (borderRadius) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceInfo,
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: SizedBox.square(
            dimension: _plusSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Своей иконки «плюс» дизайнер не присылал — в макете это
                // тонкая окружность с крестом внутри, собираем из Material.
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.textDisabled),
                ),
              ),
              child: Icon(Icons.add, color: AppColors.textDisabled),
            ),
          ),
        ),
      ),
      pill: _Pill(label: l10n.addProfileButton),
    );
  }
}

/// Скелет плитки: картинка сверху, пилюля с подписью снизу.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.color,
    required this.onTap,
    required this.image,
    required this.pill,
  });

  final Color color;
  final VoidCallback onTap;

  /// Радиус приходит сюда, чтобы картинка и её подложка скруглялись
  /// одинаково.
  final Widget Function(BorderRadius borderRadius) image;
  final Widget pill;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: _CardMetrics.radius,
        ),
        child: Padding(
          // По краю карточки отбиваем на пилюлю, она шире картинки: 24
          // против 27. Разницу добираем на самой картинке — отрицательных
          // отступов не бывает.
          padding: const EdgeInsets.fromLTRB(
            _CardMetrics.pillInset,
            _CardMetrics.topInset,
            _CardMetrics.pillInset,
            _CardMetrics.bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: _CardMetrics.sideInset - _CardMetrics.pillInset,
                ),
                child: AspectRatio(
                  aspectRatio: _CardMetrics.imageAspect,
                  child: image(_CardMetrics.radius),
                ),
              ),
              const SizedBox(height: _CardMetrics.imageToPill),
              pill,
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.trailing});

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _CardMetrics.pillHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          // Подпись в макете отбита от краёв пилюли на 16, но при длинном
          // имени важнее показать имя целиком, чем выдержать отбивку.
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.familyTileLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
