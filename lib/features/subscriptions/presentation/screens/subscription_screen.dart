import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/subscription_tier.dart';
import '../../../profile/presentation/widgets/profile_metrics.dart';
import '../../domain/entities/subscription_plan.dart';
import '../providers/subscriptions_providers.dart';

/// «Варианты подписки» — свёрстан по `design/Подписка.png`.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key, this.onSelectPlan, this.onSkip});

  final ValueChanged<SubscriptionPlan>? onSelectPlan;
  final VoidCallback? onSkip;

  /// Колонки таблицы: Basic и Silver. Basic — отсутствие подписки, карточки
  /// с ценой у него нет, но в сравнении он участвует.
  static const List<SubscriptionTier> columns = SubscriptionTier.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(planFeaturesProvider).value ?? const [];
    final plans = ref.watch(plansProvider).value ?? const [];
    final l10n = AppLocalizations.of(context)!;

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
                title: l10n.subscriptionPlansTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.subscriptionHeroTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.subscriptionHeroSubtitle,
                textAlign: TextAlign.center,
                style: AppTypography.captionMuted.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 30),
              _Section(child: _ComparisonTable(features: features)),
              const SizedBox(height: 26),
              _Section(
                child: Row(
                  children: [
                    for (final plan in plans) ...[
                      if (plan != plans.first) const SizedBox(width: 14),
                      Expanded(
                        child: _PlanCard(
                          plan: plan,
                          // Выбор запоминается здесь, а не в роутере: он
                          // нужен только на последнем шаге оплаты, где
                          // подписка и оформляется.
                          onTap: () {
                            ref
                                .read(selectedPlanProvider.notifier)
                                .select(plan.tier);
                            onSelectPlan?.call(plan);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  l10n.continueWithoutSubscription,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryBright,
                  ),
                ),
              ),
              // Отступ снизу с запасом на системную панель: на телефоне
              // (в отличие от макета) её высота съедала ссылку целиком, и
              // нажать «продолжить без подписки» было нечем. SafeArea здесь
              // не помогает — она отключена снизу, чтобы фон уходил под
              // панель, как на остальных экранах.
              SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Таблица сравнения: слева иконка с описанием, справа колонки тарифов.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable({required this.features});

  final List<PlanFeature> features;

  /// Ширина колонки тарифа по макету. Левая часть забирает остаток.
  static const double columnWidth = 74;

  /// Ширина содержимого в макете: 440 минус поля экрана.
  static const double designWidth = 400;

  static const double rowHeight = 72;

  /// Колонки ужимаются пропорционально экрану: макет снят на 440 точках,
  /// реальный телефон — 393, и там макетные 74 съедали подпись возможности
  /// («Скидки на анализы» переносилось на две строки). Ниже 60 не опускаем —
  /// дальше нечитаемо становится уже значение в ячейке.
  static double _columnWidthFor(double available) =>
      (available / designWidth * columnWidth).clamp(60.0, columnWidth);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          _table(_columnWidthFor(constraints.maxWidth)),
    );
  }

  Widget _table(double columnWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            for (final tier in SubscriptionScreen.columns)
              SizedBox(
                width: columnWidth,
                child: Text(
                  tier.columnLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        for (final feature in features)
          SizedBox(
            height: rowHeight,
            child: Row(
              children: [
                Expanded(child: _FeatureLabel(feature: feature)),
                for (final tier in SubscriptionScreen.columns)
                  SizedBox(
                    width: columnWidth,
                    child: _Cell(value: feature.valueFor(tier)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FeatureLabel extends StatelessWidget {
  const _FeatureLabel({required this.feature});

  final PlanFeature feature;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon: feature.icon, size: 34, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Тот же кегль, что и в ячейках справа: на 393 точках
              // «Скидки на анализы» четырнадцатым переносилось на две
              // строки, а в макете заголовок возможности — одна строка.
              Text(
                feature.title,
                style: AppTypography.cardItemTitle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(feature.subtitle, style: AppTypography.tileSubtitle),
            ],
          ),
        ),
      ],
    );
  }
}

/// Ячейка: либо значение, либо перечёркнутый кружок.
class _Cell extends StatelessWidget {
  const _Cell({required this.value});

  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return const Center(
        child: AppIcon(
          icon: MedixIcon.planUnavailable,
          size: 24,
          color: AppColors.primaryBright,
        ),
      );
    }
    // Через FittedBox: на узком экране колонка ужимается, и «Приоритет»
    // ломался посреди слова — «Приорит/ет». Уменьшить значение на пару
    // процентов честнее, чем разорвать слово.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value!,
          textAlign: TextAlign.center,
          // Мельче подписи слева: «Приоритет» и «До 3-5 профилей» иначе
          // переносятся посреди слова.
          style: AppTypography.cardItemTitle.copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

/// Карточка тарифа с ценой.
///
/// РАСХОЖДЕНИЕ С МАКЕТОМ, ВЫНУЖДЕННОЕ. В `design/Подписка.png` карточек две:
/// Gold залита синим, Silver рядом белая. Gold сняли с продажи, и осталась
/// одна карточка на всю ширину. Залита синим — в макете синим выделена та,
/// которую предлагают купить, а не конкретный тариф; белая карточка на почти
/// белом низу фона не читалась бы как кнопка. Дизайнеру отдано на пересмотр.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.onTap});

  final SubscriptionPlan plan;
  final VoidCallback? onTap;

  static const double height = 136;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const onCard = AppColors.textOnPrimary;
    const accent = AppColors.textOnPrimary;

    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.primaryBright,
        borderRadius: ProfileMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.tier.label,
                  style: AppTypography.titleMd.copyWith(color: onCard),
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Через FittedBox, а не Flexible с maxLines: цена
                    // четырёхзначная, и на экране уже макетного (393 точки
                    // против 440) последняя цифра просто обрезалась —
                    // «9999 ₸» читалось как «999 ₸». Лучше уменьшить кегль,
                    // чем показать цену вдесятеро меньше настоящей.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          plan.priceLabel,
                          style: AppTypography.h1.copyWith(color: accent),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        l10n.subscriptionPriceUnit,
                        style: AppTypography.tileSubtitle.copyWith(
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  l10n.subscriptionCallToAction,
                  style: AppTypography.tileSubtitle.copyWith(color: accent),
                ),
              ],
            ),
          ),
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
