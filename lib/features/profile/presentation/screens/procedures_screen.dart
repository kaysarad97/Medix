import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/medical_procedure.dart';
import '../providers/profile_providers.dart';

/// Специальность → глиф. Дизайнер не экспортировал иконки специальностей
/// (лёгкие, желудок, ухо и т. д. из `design/Предыдущие Процедуры.png`), а
/// набор специальностей открытый — заводить под каждую отдельный
/// `MedixIcon` и держать половину в `MedixIcons.pending` бессмысленно.
/// Тот же подход, что у иконки корзины/сортировки в «Перечне услуг»: сырой
/// Material `Icon`, не глиф из макета.
const Map<String, IconData> _specialtyIcons = {
  'Пульмонолог': Icons.air,
  'Гастроэнтеролог': Icons.local_dining,
  'ЛОР': Icons.hearing,
  'Дерматолог': Icons.face_retouching_natural,
  'Кардиолог': Icons.favorite,
  'Терапевт': Icons.medical_services,
  'Педиатр': Icons.child_care,
  'Аллерголог': Icons.grass,
  'Офтальмолог': Icons.visibility,
  'Невролог': Icons.psychology,
};

IconData _iconFor(String specialty) =>
    _specialtyIcons[specialty] ?? Icons.medical_information;

/// «Предыдущие процедуры» — история консультаций из мед-карты.
///
/// Свёрстан по `design/Предыдущие Процедуры.png`. У макета все видимые
/// строки — Пульмонолог/Гастроэнтеролог/ЛОР/Дерматолог — Figma-заглушка,
/// повторённая по кругу; в моке специальности и даты разные, см.
/// `MockProfileRepository.mockProcedures`.
///
/// Вкладки «Мои процедуры»/«Процедуры ребёнка»/«Процедуры старших» отсылают
/// к семейному доступу (`lib/features/family_access/`), которого ещё нет —
/// фильтр работает только по полю [FamilyScope] в моке, реальных профилей
/// детей и старших не подключает.
///
/// В макете первая карточка списка выделена более ярким фоном — в
/// присланных кадрах непонятно, что это значит (не «непрочитано», не
/// «сегодня»), поэтому здесь все карточки одинаковые, без выборочной
/// подсветки.
///
/// Строка «посмотреть результаты» ведёт к лабораторным файлам пользователя.
class ProceduresScreen extends ConsumerWidget {
  const ProceduresScreen({super.key});

  static const double _screenH = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final procedures = ref.watch(visibleProceduresProvider);
    final scope = ref.watch(procedureScopeFilterProvider);
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
                title: l10n.previousProceduresTitle,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 17),
              _SearchField(
                onChanged: (value) => ref
                    .read(procedureSearchQueryProvider.notifier)
                    .update(value),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.proceduresResultsCount(procedures.length),
                style: AppTypography.cardItemMeta,
              ),
              const SizedBox(height: 12),
              _ScopeTabs(
                selected: scope,
                onSelect: (value) => ref
                    .read(procedureScopeFilterProvider.notifier)
                    .select(value),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: procedures.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: procedures.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _ProcedureRow(
                          procedure: procedures[index],
                          onTap: () => context.push(Routes.labResults),
                        ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
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
                    hintText: AppLocalizations.of(
                      context,
                    )!.proceduresSearchHint,
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

class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({required this.selected, required this.onSelect});

  final FamilyScope selected;
  final ValueChanged<FamilyScope> onSelect;

  static String _labelFor(FamilyScope scope, AppLocalizations l10n) =>
      switch (scope) {
        FamilyScope.self => l10n.familyScopeSelf,
        FamilyScope.child => l10n.familyScopeChild,
        FamilyScope.senior => l10n.familyScopeSenior,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final scope in FamilyScope.values) ...[
            if (scope != FamilyScope.values.first) const SizedBox(width: 8),
            _TabButton(
              label: _labelFor(scope, l10n),
              active: scope == selected,
              onTap: () => onSelect(scope),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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

class _ProcedureRow extends StatelessWidget {
  const _ProcedureRow({required this.procedure, required this.onTap});

  final MedicalProcedure procedure;
  final VoidCallback onTap;

  static const double _photoSize = 56;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.surfaceWhite,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBright,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: _photoSize,
                    height: _photoSize,
                    child: Icon(
                      _iconFor(procedure.specialty),
                      color: AppColors.textOnPrimary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.consultationWithLabel,
                        style: AppTypography.linkSmall,
                      ),
                      Text(
                        procedure.doctorName,
                        style: AppTypography.titleMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        procedure.specialty,
                        style: AppTypography.linkSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceChip,
                          borderRadius: AppRadius.allPill,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            procedure.dateLabel,
                            style: AppTypography.chipLabel.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const AppIcon(
                      icon: MedixIcon.chevronRight,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 74,
                      child: Text(
                        AppLocalizations.of(context)!.viewResultsLinkLabel,
                        textAlign: TextAlign.right,
                        style: AppTypography.linkSmall,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
