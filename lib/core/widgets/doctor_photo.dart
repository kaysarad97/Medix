import 'package:flutter/material.dart';

import '../../shared/models/medix_doctor_photos.dart';

/// Фотография врача: с бэкенда, если она есть, иначе портрет из набора
/// дизайнера по ключу — см. [MedixDoctorPhotos.forSeed].
///
/// Размер задаёт родитель: на карточке каталога это круг 56, в шапке профиля
/// врача — 137×155, на звонке — во весь экран. Кадрируется по верхнему краю:
/// исходники сняты в рост, и при обрезке по центру голова уезжает вверх.
class DoctorPhoto extends StatelessWidget {
  const DoctorPhoto({
    super.key,
    required this.seed,
    this.url,
    this.borderRadius,
  });

  /// Идентификатор врача, а где его нет — имя или название специальности.
  final String seed;

  final String? url;

  /// `null` — круг.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = url == null
        ? Image.asset(
            MedixDoctorPhotos.forSeed(seed),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          )
        : Image.network(
            url!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          );

    return borderRadius == null
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
