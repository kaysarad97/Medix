import 'package:flutter/material.dart';

import '../../shared/models/medix_doctor_photos.dart';

/// Фотография врача: с бэкенда, если она есть, иначе портрет из набора
/// дизайнера по ключу — см. [MedixDoctorPhotos.forSeed].
///
/// Размер задаёт родитель: на карточке каталога это круг 56, в шапке профиля
/// врача — 137×155, на звонке — во весь экран.
///
/// Кадрируется по-разному, и это не прихоть. В круглой аватарке портрет
/// вписывается целиком и садится на нижний край: исходники сняты по пояс, и
/// при обрезке «по размеру круга» халат упирался в кромку — снизу выходил
/// прямой срез вместо круга, как и заметили на живом телефоне. В прямоугольном
/// вырезе шапки врача, наоборот, портрет должен закрывать всё поле, поэтому
/// там обрезка по верхнему краю: иначе голова уезжает вверх.
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
    final isRound = borderRadius == null;
    final fit = isRound ? BoxFit.contain : BoxFit.cover;
    final alignment = isRound ? Alignment.bottomCenter : Alignment.topCenter;

    final image = url == null
        ? Image.asset(
            MedixDoctorPhotos.forSeed(seed),
            fit: fit,
            alignment: alignment,
          )
        : Image.network(url!, fit: fit, alignment: alignment);

    return isRound
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
