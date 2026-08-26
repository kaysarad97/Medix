import 'package:flutter/material.dart';

/// Аватар пользователя.
///
/// Источников два: набор картинок в сборке, из которого пользователь
/// выбирает себе одну, и ссылка с бэкенда — на случай, когда аватарки
/// начнут приходить оттуда. Пока не выбрано ничего, видна одна подложка,
/// чтобы вёрстка не прыгала.
///
/// Подложка — градиент из макета (`icons/Фото.png`), а не заливка цветом:
/// в `design/Профиль.png` под лицом лежит сиренево-голубой переход, и
/// картинки аватаров нарисованы в расчёте на него.
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

  /// Градиентная подложка из макета.
  static const String backgroundAsset = 'assets/images/avatar_bg.png';

  @override
  Widget build(BuildContext context) {
    final Widget? image;
    if (asset != null) {
      image = Image.asset(asset!, fit: BoxFit.cover);
    } else if (url != null) {
      image = Image.network(url!, fit: BoxFit.cover);
    } else {
      image = null;
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: ClipRRect(
          borderRadius:
              borderRadius ?? BorderRadius.circular(size.shortestSide / 2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Градиент лежит и под выбранной картинкой: аватары дизайнера
              // нарисованы с прозрачными углами, и без подложки на их месте
              // просвечивал бы фон экрана.
              Image.asset(backgroundAsset, fit: BoxFit.cover),
              ?image,
            ],
          ),
        ),
      ),
    );
  }
}
