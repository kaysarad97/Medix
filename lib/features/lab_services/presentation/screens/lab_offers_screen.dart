import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_offer.dart';
import '../../domain/entities/lab_service.dart';
import '../providers/lab_services_providers.dart';

/// «Партнерские лаборатории» — сколько та же корзина стоит у других.
///
/// Свёрстан по `design/Сравнение корзины.png`. Открывается кнопкой
/// «Сравнить цены» из шторки корзины.
class LabOffersScreen extends ConsumerWidget {
  const LabOffersScreen({super.key});

  static const double screenH = 21;
  static const double topBarTop = 36;
  static const double topBarToCard = 26;

  /// Карточка корзины кончается на y 402, подпись «Другие предложения» —
  /// на 427, макет 440×1077.
  static const double cardGap = 20;

  /// Между карточками предложений: низ первой 781, верх второй 800.
  static const double offerGap = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(cartServicesProvider);
    final total = ref.watch(cartTotalProvider);
    final offers = ref.watch(labOffersProvider).value ?? const <LabOffer>[];
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
                title: l10n.partnerLabsTitle,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: topBarToCard),
              _Section(
                child: _OwnCartCard(
                  // Название нашей лаборатории придёт с бэкендом вместе с
                  // партнёрами; в макете это тоже подстановка.
                  labName: 'КДЛ «Название»',
                  items: [for (final s in services) ..._itemsOf(s)],
                  total: total,
                ),
              ),
              const SizedBox(height: cardGap),
              _Section(
                child: Text(
                  l10n.otherOffersTitle,
                  style: AppTypography.captionMuted,
                ),
              ),
              for (final (index, offer) in offers.indexed) ...[
                const SizedBox(height: offerGap),
                _Section(
                  child: _OfferCard(offer: offer, index: index),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Комплекс в списке раскрывается своим составом: сравнивать надо
  /// одинаковые наборы, а не названия комплексов.
  static List<String> _itemsOf(LabService service) =>
      service.includes.isEmpty ? [service.name] : service.includes;
}

class _OwnCartCard extends StatelessWidget {
  const _OwnCartCard({
    required this.labName,
    required this.items,
    required this.total,
  });

  final String labName;
  final List<String> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.cartAtLabTitle(labName),
            style: AppTypography.analysisValue,
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Шаг строк в макете 18: строка 12-м кеглем занимает 15,
                  // остаётся 3 на отбивку.
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '·  $item',
                        style: AppTypography.cardItemMeta,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(l10n.cartTotalLabel, style: AppTypography.cartTotal),
              const Spacer(),
              Text('$total ₸', style: AppTypography.cartTotalValue),
            ],
          ),
        ],
      ),
    );
  }
}

/// Карточка партнёра: шапка с рейтингом, цена на тот же набор и кнопка.
class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.index});

  final LabOffer offer;

  /// Номер в списке: карточки чередуются по фону.
  final int index;

  /// Замеры по `design/Сравнение корзины.png`, макет 440×1077.
  /// Круг логотипа x 34…102.
  static const double logoSize = 68;

  /// Логотип 34…102 → чипы от 126.
  static const double _logoToText = 24;

  /// Шапка → плашка цены (низ строки 574, верх плашки 596) и плашка → кнопка
  /// (низ 677, верх 697).
  static const double _blockGap = 20;

  /// Чётные карточки синие, нечётные — серые, как в макете.
  ///
  /// ВОПРОС ДИЗАЙНЕРУ. В макете видно ровно две карточки, и по ним нельзя
  /// отличить чередование от подсветки лучшей цены: синяя как раз дешевле.
  /// Взято чередование — при трёх партнёрах оно даст ритм, а подсветка
  /// одной карточки из макета никак не следует.
  Color get _background =>
      index.isEven ? AppColors.accentSofter : AppColors.surface;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      color: _background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Логотипов партнёров нет — дизайнер отдал заглушку «ЛОГО».
              SizedBox.square(
                dimension: logoSize,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceWhite,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: _logoToText),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        _Pill(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon(
                                icon: MedixIcon.star,
                                size: 14,
                                color: AppColors.primaryBright,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                offer.ratingLabel,
                                style: AppTypography.chipLabel,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          child: Text(
                            offer.isOpen
                                ? l10n.placeOpenStatus
                                : l10n.placeClosedStatus,
                            style: AppTypography.chipLabel.copyWith(
                              color: offer.isOpen
                                  ? AppColors.scaleNormal
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          child: Text(
                            offer.distanceLabel,
                            style: AppTypography.chipLabel,
                          ),
                        ),
                      ],
                    ),
                    // Чипы → название → адрес: в макете между ними по 13.
                    const SizedBox(height: 13),
                    Text(offer.labName, style: AppTypography.analysisValue),
                    const SizedBox(height: 13),
                    Text(offer.address, style: AppTypography.tileSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: _blockGap),
          _PriceRow(offer: offer),
          const SizedBox(height: _blockGap),
          _OrderButton(labName: offer.labName),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.child});

  final Widget child;

  /// Чипы в макете y 477…515. Высота задана явно, а не отступами: у трёх
  /// чипов разное содержимое (иконка со звездой, короткое и длинное слово),
  /// и на отступах они разъехались бы по высоте.
  static const double height = 39;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.offer});

  final LabOffer offer;

  /// Плашка в макете y 596…677, кругляш внутри 44.
  static const double height = 82;
  static const double _chipSize = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allMd,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              const AppIconChip(icon: MedixIcon.labTest, size: _chipSize),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.priceAtLab(offer.labName),
                      style: AppTypography.bodyMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n.identicalTestsHint,
                      style: AppTypography.captionMuted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(offer.priceLabel, style: AppTypography.cardTitleAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  const _OrderButton({required this.labName});

  final String labName;

  /// Кнопка в макете y 697…768, кругляш внутри 44.
  static const double height = 72;
  static const double _chipSize = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.primaryBright,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Записи в лабораторию у бэкенда нет — кнопка ждёт эндпоинта.
          onTap: null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            child: Row(
              children: [
                const AppIconChip(icon: MedixIcon.labTest, size: _chipSize),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.orderAtLab(labName),
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: LabOffersScreen.screenH),
      child: child,
    );
  }
}
