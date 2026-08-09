import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/medix_avatars.dart';
import '../providers/profile_providers.dart';

/// «Выбор аватарки» — сетка из двенадцати картинок, зашитых в сборку.
///
/// Свёрстан по `design/АВАТАРКИ.png` (440×956). Открывается по подписи
/// «изменить аватара» с экрана настроек профиля.
///
/// Своё фото не загружается и здесь: снимок лица — биометрия, её обработка
/// требует отдельного согласия и защищённого хранения (см. [MedixAvatars]).
class AvatarPickerScreen extends ConsumerWidget {
  const AvatarPickerScreen({super.key});

  /// Верх экрана → верхняя строка, как на остальных внутренних экранах.
  static const double topBarTop = 36;

  /// Низ верхней строки 132 → верх первого ряда 174.
  static const double topBarToGrid = 42;

  /// Плитка 117×135 с радиусом 16 — замеры по макету. Пропорция совпадает
  /// с подложкой `assets/images/avatar_bg.png` (131×151), это один и тот же
  /// прямоугольник.
  static const double tileWidth = 117;
  static const double tileHeight = 135;
  static const double tileRadius = 16;

  /// Поля экрана: плитки идут x 21…419.
  static const double screenH = 21;

  /// Между плитками: 23.5 по горизонтали и 38.5 по вертикали.
  static const double columnGap = 23.5;
  static const double rowGap = 38.5;

  /// Белое кольцо у выбранной. Рисуется снаружи плитки, поэтому ячейка
  /// сетки на две его толщины больше самой плитки.
  static const double ringWidth = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(userAvatarProvider) ?? MedixAvatars.fallback;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: topBarTop),
            ScreenTopBar(
              title: l10n.avatarPickerTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: topBarToGrid),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: screenH),
                itemCount: MedixAvatars.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  // Ячейка больше плитки на кольцо с обеих сторон, а
                  // зазоры на столько же меньше — расстояние между
                  // плитками остаётся замеренным.
                  childAspectRatio:
                      (tileWidth + ringWidth * 2) /
                      (tileHeight + ringWidth * 2),
                  crossAxisSpacing: columnGap - ringWidth * 2,
                  mainAxisSpacing: rowGap - ringWidth * 2,
                ),
                itemBuilder: (context, index) {
                  final asset = MedixAvatars.all[index];
                  return _AvatarTile(
                    asset: asset,
                    selected: asset == selected,
                    onTap: () => ref
                        .read(avatarSelectionProvider.notifier)
                        .select(asset),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            AvatarPickerScreen.tileRadius + AvatarPickerScreen.ringWidth,
          ),
          border: Border.all(
            // Кольцо занимает место всегда, иначе выбор дёргал бы сетку.
            color: selected ? AppColors.surfaceWhite : Colors.transparent,
            width: AvatarPickerScreen.ringWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: LayoutBuilder(
            builder: (context, constraints) => UserAvatar(
              asset: asset,
              size: Size(constraints.maxWidth, constraints.maxHeight),
              borderRadius: BorderRadius.circular(
                AvatarPickerScreen.tileRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
