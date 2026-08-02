import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Аватар пользователя.
///
/// Источников два: набор картинок в сборке, из которого пользователь
/// выбирает себе одну, и ссылка с бэкенда — на случай, когда аватарки
/// начнут приходить оттуда. Пока не выбрано ничего, рисуется подложка,
/// чтобы вёрстка не прыгала.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.asset,
    this.url,
    required this.size,
    this.borderRadius,
    this.onTap,
  });

  /// Путь к картинке из сборки — см. `MedixAvatars`.
  final String? asset;

  /// Ссылка с бэкенда. Проигрывает [asset], если заданы оба.
  final String? url;

  final Size size;

  /// Скругление. По умолчанию круг — так аватар выглядит в шапке главной
  /// и в строке настроек; на экране профиля углы скруглены на 24.
  final BorderRadius? borderRadius;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (asset != null) {
      image = Image.asset(asset!, fit: BoxFit.cover);
    } else if (url != null) {
      image = Image.network(url!, fit: BoxFit.cover);
    } else {
      image = const DecoratedBox(
        decoration: BoxDecoration(color: AppColors.accentSoft),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(size.shortestSide / 2),
          child: image,
        ),
      ),
    );
  }
}
