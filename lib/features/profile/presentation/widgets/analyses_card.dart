import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/analysis_result.dart';
import 'profile_metrics.dart';
import '../../../../core/widgets/section_header.dart';

/// «Ваши анализы»: переключатель вкладок и список результатов со шкалой.
class AnalysesCard extends StatelessWidget {
  const AnalysesCard({
    super.key,
    required this.analyses,
    required this.filter,
    required this.title,
    this.onFilterChanged,
    this.onOpenAll,
  });

  final List<AnalysisResult> analyses;
  final AnalysesFilter filter;

  /// «Ваши анализы» у пользователя, «Анализы ребёнка» / «Анализы Имя
  /// Фамилия» на карточке члена семьи — см. `design/Моя Семья Ребенок.png`
  /// и `design/Моя Семья Старшие.png`. Локализованное значение всегда
  /// приходит от вызывающей стороны: у `BuildContext` внутри виджета нет
  /// доступа к тому, каким текстом его вызвали как значение по умолчанию.
  final String title;

  final ValueChanged<AnalysesFilter>? onFilterChanged;
  final VoidCallback? onOpenAll;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFF7F7F7),
      borderRadius: ProfileMetrics.allRadius,
      padding: const EdgeInsets.all(ProfileMetrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            icon: MedixIcon.analyses,
            title: title,
            onTap: onOpenAll,
          ),
          const SizedBox(height: ProfileMetrics.titleToToggle),
          _FilterToggle(value: filter, onChanged: onFilterChanged),
          const SizedBox(height: ProfileMetrics.toggleToList),
          for (final analysis in analyses) ...[
            if (analysis != analyses.first)
              const SizedBox(height: ProfileMetrics.analysisRowGap),
            _AnalysisRow(analysis: analysis),
          ],
        ],
      ),
    );
  }
}

/// Две вкладки в голубой пилюле; выбранная — белая пилюля внутри.
class _FilterToggle extends StatelessWidget {
  const _FilterToggle({required this.value, this.onChanged});

  final AnalysesFilter value;
  final ValueChanged<AnalysesFilter>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.toggleHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceToggle,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.all(ProfileMetrics.togglePadding),
          child: Row(
            children: [
              for (final option in AnalysesFilter.values)
                Expanded(
                  child: _Tab(
                    option: option,
                    selected: option == value,
                    onTap: () => onChanged?.call(option),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AnalysesFilter option;
  final bool selected;
  final VoidCallback onTap;

  static String _labelFor(AnalysesFilter option, AppLocalizations l10n) =>
      switch (option) {
        AnalysesFilter.changed => l10n.analysesFilterChanged,
        AnalysesFilter.all => l10n.analysesFilterAll,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceWhite : Colors.transparent,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _labelFor(option, AppLocalizations.of(context)!),
              // Мельче остальных чипов: длинная подпись «Анализы с
              // изменениями» в половину переключателя иначе не помещается.
              style: AppTypography.chipLabel.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Строка результата: название с референсом, значение и шкала.
class _AnalysisRow extends StatelessWidget {
  const _AnalysisRow({required this.analysis});

  final AnalysisResult analysis;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.analysisRowHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: ProfileMetrics.allRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(analysis.name, style: AppTypography.analysisName),
                    const SizedBox(height: 6),
                    Text(
                      analysis.referenceLabel,
                      style: AppTypography.analysisReference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Не Expanded: значение занимает столько, сколько нужно, а
              // остаток достаётся названию. Поровну не делим — «24.8
              // мкмоль/л» тогда не помещается и обрезается многоточием.
              Text(analysis.valueLabel, style: AppTypography.analysisValue),
              const SizedBox(width: 8),
              ReferenceScale(position: analysis.position),
            ],
          ),
        ),
      ),
    );
  }
}

/// Шкала «ниже нормы — норма — выше нормы» с точкой на значении.
///
/// Три отрезка равной длины: в макете зелёная середина такая же, как
/// жёлтый и красный края, хотя по значениям интервал нормы шире.
class ReferenceScale extends StatelessWidget {
  const ReferenceScale({super.key, required this.position});

  /// 0…1 вдоль всей шкалы.
  final double position;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProfileMetrics.scaleWidth,
      height: ProfileMetrics.scaleDotSize,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          const Row(
            children: [
              Expanded(child: _Segment(color: AppColors.scaleLow)),
              Expanded(child: _Segment(color: AppColors.scaleNormal)),
              Expanded(child: _Segment(color: AppColors.scaleHigh)),
            ],
          ),
          Align(
            // −1 слева, +1 справа: переводим 0…1 в эту шкалу.
            alignment: Alignment(position * 2 - 1, 0),
            child: const _Dot(),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.scaleThickness,
      child: DecoratedBox(decoration: BoxDecoration(color: color)),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ProfileMetrics.scaleDotSize,
      height: ProfileMetrics.scaleDotSize,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.scaleNormal, width: 2),
      ),
    );
  }
}
