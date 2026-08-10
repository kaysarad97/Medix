import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/lab_service.dart';
import '../providers/lab_services_providers.dart';

/// Показывает корзину поверх каталога.
///
/// `useRootNavigator: false` — шторка должна лежать внутри текущей ветки
/// навигации, иначе она перекроет и таб-бар, которого в макете не видно
/// только потому, что он под ней.
Future<void> showCartSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => CartSheet(
      onCompare: () {
        Navigator.of(sheetContext).pop();
        context.push(Routes.labOffers);
      },
      // Заказов у бэкенда пока нет: кнопка ждёт эндпоинта.
      onOrder: null,
    ),
  );
}

/// Шторка «Моя Корзина» над «Перечнем услуг».
///
/// Свёрстана по `design/Моя корзина.png`. Макет выгружен шириной 450, а не
/// 440, как остальные, поэтому замеры переведены множителем 440/450.
///
/// Именно шторка, а не отдельный экран: в макете за ней видны поиск и
/// вкладки каталога, то есть каталог остаётся на месте.
class CartSheet extends ConsumerWidget {
  const CartSheet({super.key, this.onCompare, this.onOrder});

  /// «Сравнить цены» — переход к партнёрам.
  final VoidCallback? onCompare;

  /// «Сделать заказ». Заказов у бэкенда пока нет.
  final VoidCallback? onOrder;

  /// Шторка занимает низ экрана: верх на 322 при высоте 956.
  static const double topOffset = 322;

  /// Поля шторки: x 18…422 при ширине 440.
  static const double sheetInset = 18;

  /// Кромка скруглена; точное значение с макета снять не удалось — она
  /// почти сливается с фоном. Взято по виду, уточнить у дизайнера.
  static const double sheetRadius = 24;

  /// Внутренние поля: белая карточка начинается на 46 при шторке с 18.
  static const double contentPadding = 28;

  /// Между карточками позиций.
  static const double rowGap = 10;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(cartServicesProvider);
    final total = ref.watch(cartTotalProvider);
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            contentPadding,
            20,
            contentPadding,
            20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.cartTitle, style: AppTypography.sectionTitle),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < services.length; i++) ...[
                        if (i > 0) const SizedBox(height: rowGap),
                        _CartRow(number: i + 1, service: services[i]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(l10n.cartTotalLabel, style: AppTypography.cartTotal),
                  const Spacer(),
                  Text('$total ₸', style: AppTypography.cartTotalValue),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _CartAction(
                      icon: Icons.shopping_cart_outlined,
                      label: l10n.cartPlaceOrder,
                      filled: true,
                      onTap: onOrder,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CartAction(
                      icon: Icons.percent,
                      label: l10n.cartComparePrices,
                      filled: false,
                      onTap: onCompare,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Позиция корзины: номер слева, белая карточка с названием и ценой.
class _CartRow extends StatelessWidget {
  const _CartRow({required this.number, required this.service});

  final int number;
  final LabService service;

  /// Карточка позиции: y 377…473 при высоте экрана 956 — 94 без состава.
  static const double minHeight = 94;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          child: Text('$number', style: AppTypography.cardItemMeta),
        ),
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: AppRadius.allMd,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(service.name, style: AppTypography.analysisValue),
                    // Состав комплекса — списком, как в макете. У отдельного
                    // анализа его нет, и блок не рисуется вовсе.
                    if (service.includes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      for (final item in service.includes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '·  $item',
                            style: AppTypography.cardItemMeta,
                          ),
                        ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          l10n.cartPriceLabel,
                          style: AppTypography.tileSubtitle,
                        ),
                        const Spacer(),
                        Text(
                          service.priceLabel,
                          style: AppTypography.cartRowPrice,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Кнопка под корзиной: кружок с глифом и подпись в две строки.
class _CartAction extends StatelessWidget {
  const _CartAction({
    required this.icon,
    required this.label,
    required this.filled,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// Залитая — «Сделать заказ», светлая — «Сравнить цены».
  final bool filled;

  final VoidCallback? onTap;

  static const double height = 64;
  static const double glyphCircle = 36;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: filled ? AppColors.accentSofter : AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: glyphCircle,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceWhite,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: filled
                        ? AppTypography.bodyMd
                        : AppTypography.bodyMd.copyWith(
                            color: AppColors.primaryBright,
                          ),
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
