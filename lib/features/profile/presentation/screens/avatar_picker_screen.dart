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
/// Пользователь может оставить иллюстрацию или осознанно выбрать собственное
/// фото в системном picker. Файл отправляется напрямую в хранилище через
/// короткоживущую presigned-форму и не сохраняется приложением локально.
class AvatarPickerScreen extends ConsumerStatefulWidget {
  const AvatarPickerScreen({super.key});

  static const double topBarTop = 36;
  static const double topBarToGrid = 18;
  static const double tileWidth = 117;
  static const double tileHeight = 135;
  static const double tileRadius = 16;
  static const double screenH = 21;
  static const double columnGap = 23.5;
  static const double rowGap = 38.5;
  static const double ringWidth = 3;

  @override
  ConsumerState<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends ConsumerState<AvatarPickerScreen> {
  bool uploading = false;

  Future<void> _upload() async {
    if (uploading) return;
    final file = await ref.read(avatarFilePickerProvider).pick();
    if (file == null || !mounted) return;

    setState(() => uploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(avatarUploadServiceProvider).upload(file);
      await ref.read(avatarSelectionProvider.notifier).clear();
      ref.invalidate(profileProvider);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.avatarUploadSuccess)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.avatarUploadError)));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = ref.watch(userAvatarProvider) ?? MedixAvatars.fallback;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AvatarPickerScreen.topBarTop),
            ScreenTopBar(
              title: l10n.avatarPickerTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AvatarPickerScreen.screenH,
              ),
              child: OutlinedButton.icon(
                onPressed: uploading ? null : _upload,
                icon: uploading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_a_photo_outlined),
                label: Text(l10n.uploadOwnPhotoAction),
              ),
            ),
            const SizedBox(height: AvatarPickerScreen.topBarToGrid),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AvatarPickerScreen.screenH,
                ),
                itemCount: MedixAvatars.all.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  // Ячейка больше плитки на кольцо с обеих сторон, а
                  // зазоры на столько же меньше — расстояние между
                  // плитками остаётся замеренным.
                  childAspectRatio:
                      (AvatarPickerScreen.tileWidth +
                          AvatarPickerScreen.ringWidth * 2) /
                      (AvatarPickerScreen.tileHeight +
                          AvatarPickerScreen.ringWidth * 2),
                  crossAxisSpacing:
                      AvatarPickerScreen.columnGap -
                      AvatarPickerScreen.ringWidth * 2,
                  mainAxisSpacing:
                      AvatarPickerScreen.rowGap -
                      AvatarPickerScreen.ringWidth * 2,
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
