import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/doctor_cabinet_providers.dart';
import '../widgets/doctor_own_review_card.dart';
import '../widgets/doctor_profile_metrics.dart';

/// «Отзывы о Вас» — кабинет врача.
///
/// Свёрстан по `design/для врача от клиники/Отзывы о враче.png` (общий
/// для клиники и фрилансера — файл byte-в-byte одинаков в обоих
/// комплектах). «Топ отзывов» — первые три записи в карусели с точками,
/// «Остальные отзывы» — тот же остаток списком; макет не размечает,
/// сколько именно отзывов входит в топ, три — по числу точек на карусели.
class DoctorReviewsScreen extends ConsumerStatefulWidget {
  const DoctorReviewsScreen({super.key});

  @override
  ConsumerState<DoctorReviewsScreen> createState() =>
      _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends ConsumerState<DoctorReviewsScreen> {
  static const int _topCount = 3;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reviews = ref.watch(doctorOwnReviewsProvider).value ?? const [];
    final top = reviews.take(_topCount).toList();
    final rest = reviews.skip(_topCount).toList();

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DoctorProfileMetrics.screenH,
                ),
                child: ScreenTopBar(
                  title: l10n.doctorReviewsScreenTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: DoctorProfileMetrics.topBarToPhoto),
              if (top.isNotEmpty) ...[
                _Section(
                  child: AppCard(
                    color: AppColors.accentSofter,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.topReviewsTitle,
                          style: AppTypography.cardItemMeta,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: DoctorOwnReviewCard.height,
                          child: PageView.builder(
                            controller: _controller,
                            itemCount: top.length,
                            onPageChanged: (page) =>
                                setState(() => _page = page),
                            itemBuilder: (context, index) =>
                                DoctorOwnReviewCard(review: top[index]),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Dots(count: top.length, active: _page),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DoctorProfileMetrics.cardGap),
              ],
              if (rest.isNotEmpty)
                _Section(
                  child: AppCard(
                    padding: const EdgeInsets.all(
                      DoctorProfileMetrics.cardPadding,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.doctorOtherReviewsTitle,
                          style: AppTypography.cardItemMeta,
                        ),
                        const SizedBox(height: 12),
                        for (final review in rest) ...[
                          if (review != rest.first) const SizedBox(height: 12),
                          DoctorOwnReviewCard(review: review),
                        ],
                      ],
                    ),
                  ),
                ),
              SizedBox(
                height:
                    DoctorProfileMetrics.cardGap +
                    MediaQuery.paddingOf(context).bottom,
              ),
            ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: DoctorProfileMetrics.screenH,
      ),
      child: child,
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == active
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
