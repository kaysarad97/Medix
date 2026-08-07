import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_service.dart';
import '../providers/lab_services_providers.dart';

/// Перечень услуг: каталог анализов и комплексов с корзиной.
///
/// Свёрстан по `design/Перечень услуг.png`. У макета в шапке написано
/// «Поиск врача» — копипаста из соседнего экрана, заказчик подтвердил
/// правильное название: «Перечень услуг». Буква «А» в макете повторена
/// четыре раза подряд (Figma-плейсхолдер) — в моке услуги реальные и
/// разных букв, см. `MockLabServicesRepository`.
///
/// Отдельного экрана корзины нет — макета для него не прислали. Строка
/// каталога по нажатию добавляется/убирается из корзины, счётчик в шапке
/// обновляется; открыть саму корзину пока негде.
class LabServicesScreen extends ConsumerWidget {
  const LabServicesScreen({super.key});

  static const double _screenH = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(visibleLabServicesProvider);
    final kind = ref.watch(labServiceKindFilterProvider);
    final cartCount = ref.watch(labServicesCartProvider).length;
    final letters = grouped.keys.toList()..sort();
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              ScreenTopBar(
                title: l10n.labServicesTitle,
                onBack: () => context.pop(),
                trailing: _CartBadge(count: cartCount),
              ),
              const SizedBox(height: 17),
              _SearchField(
                onChanged: (value) => ref
                    .read(labServiceSearchQueryProvider.notifier)
                    .update(value),
              ),
              const SizedBox(height: 12),
              _KindToggle(
                selected: kind,
                onSelect: (value) => ref
                    .read(labServiceKindFilterProvider.notifier)
                    .select(value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: letters.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: letters.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final letter = letters[index];
                          return _LetterGroup(
                            letter: letter,
                            services: grouped[letter]!,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceChip,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 18,
              color: AppColors.primary,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            const AppIcon(icon: MedixIcon.search, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: TextField(
                  onChanged: onChanged,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.labServiceSearchHint,
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.selected, required this.onSelect});

  final LabServiceKind selected;
  final ValueChanged<LabServiceKind> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      LabServiceKind.individual: l10n.labServiceIndividualTab,
      LabServiceKind.bundle: l10n.labServiceBundleTab,
    };
    return Row(
      children: [
        for (final kind in labels.keys) ...[
          if (kind != labels.keys.first) const SizedBox(width: 8),
          _ToggleButton(
            label: labels[kind]!,
            active: kind == selected,
            onTap: () => onSelect(kind),
          ),
        ],
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : AppColors.surfaceDisabled,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: AppTypography.chipLabel.copyWith(
              color: active ? AppColors.primary : AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterGroup extends ConsumerWidget {
  const _LetterGroup({required this.letter, required this.services});

  final String letter;
  final List<LabService> services;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(labServicesCartProvider);

    return AppCard(
      color: AppColors.surfaceWhite,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(letter, style: AppTypography.sectionTitle),
          const SizedBox(height: 8),
          for (final service in services)
            _ServiceRow(
              service: service,
              inCart: cart.contains(service.id),
              onTap: () =>
                  ref.read(labServicesCartProvider.notifier).toggle(service.id),
            ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.inCart,
    required this.onTap,
  });

  final LabService service;
  final bool inCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: inCart ? AppColors.accentSofter : Colors.transparent,
      borderRadius: AppRadius.allSm,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.primaryBright,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                service.priceLabel,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primaryBright,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context)!.emptyResultsLabel,
        style: AppTypography.cardItemMeta,
      ),
    );
  }
}
