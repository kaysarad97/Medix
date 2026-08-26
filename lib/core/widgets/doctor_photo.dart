import 'package:flutter/material.dart';

import '../../shared/models/medix_doctor_photos.dart';

/// Фотография врача: с бэкенда, если она есть, иначе портрет из набора
/// дизайнера по ключу — см. [MedixDoctorPhotos.forSeed].
///
/// Размер задаёт родитель: на карточке каталога это круг 56, в шапке профиля
/// врача — 137×155, на звонке — во весь экран.
///
/// Кадрируется всегда одинаково: портрет закрывает всё поле, лишнее снизу
/// срезается. Выравнивание по верхнему краю — иначе голова уезжает за кромку.
///
/// ДВАЖДЫ ПРАВЛЕНО, ЧИТАТЬ ПЕРЕД ТРЕТЬИМ РАЗОМ. Сначала в круге стояла та же
/// обрезка, но по нижнему краю, и халат упирался в кромку — снизу выходил
/// прямой срез. Лечили это вписыванием целиком (`contain`) — и стало хуже:
/// исходник снят на белом фоне со скруглёнными углами, и в круге вместо
/// портрета появлялась белая табличка с прямыми боками, из-за которой круг
/// и читался «каким-то овальным». Оба раза виноват был не круг, а
/// выравнивание. Белый фон исходника при обрезке во всё поле работает как
/// студийная подложка и заполняет круг целиком.
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
    const fit = BoxFit.cover;
    const alignment = Alignment.topCenter;

    final image = url == null
        ? Image.asset(
            MedixDoctorPhotos.forSeed(seed),
            fit: fit,
            alignment: alignment,
          )
        : Image.network(url!, fit: fit, alignment: alignment);

    return borderRadius == null
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
