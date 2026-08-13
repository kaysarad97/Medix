import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/doctor.dart';
import 'doctor_metrics.dart';

/// Шапка врача: фотография-вырезка слева, чипы и подписи справа.
///
/// Одинакова на `design/Профиль врача + запись.png` и `design/Ваша
/// Запись.png`.
class DoctorHeader extends StatelessWidget {
  const DoctorHeader({super.key, required this.doctor});

  final Doctor doctor;

  /// Фото 23…160, текстовая колонка с 176 — между ними 16.
  static const double photoToInfo = 16;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.photoSize.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: DoctorMetrics.photoLeft),
          _Photo(url: doctor.photoUrl),
          const SizedBox(width: photoToInfo),
          Expanded(
            child: Padding(
              // Чипы начинаются на 12 ниже верхней кромки фотографии.
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Chips(doctor: doctor),
                  const SizedBox(height: DoctorMetrics.chipsToName),
                  Text(
                    doctor.fullName,
                    style: AppTypography.doctorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DoctorMetrics.nameToSpecialty),
                  Text(
                    doctor.specialty,
                    style: AppTypography.doctorSpecialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DoctorMetrics.specialtyToClinic),
                  Text(
                    // Пусто — строка остаётся, но пустая: без неё подписи
                    // выше сдвинулись бы вниз, а шапка фиксированной высоты.
                    doctor.clinic ?? '',
                    style: AppTypography.doctorClinic,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: DoctorMetrics.screenH),
        ],
      ),
    );
  }
}

/// Фотография врача.
///
/// В макете это вырезка без рамки, поэтому [BoxFit.contain] и никакой
/// обводки. Пока фото не приходит с бэкенда — подложка, как у аватара
/// на главной.
class _Photo extends StatelessWidget {
  const _Photo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DoctorMetrics.photoSize.width,
      height: DoctorMetrics.photoSize.height,
      child: url == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.accentSoft.withValues(alpha: 0.5),
                borderRadius: AppRadius.allLg,
              ),
            )
          : Image.network(url!, fit: BoxFit.contain),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DoctorMetrics.chipHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Иначе чипы сожмутся до высоты своего текста и повиснут по центру.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Chip(
            leading: const AppIcon(
              icon: MedixIcon.star,
              size: 16,
              color: AppColors.primaryBright,
            ),
            label: doctor.ratingLabel,
          ),
          if (doctor.experienceLabel != null) ...[
            const SizedBox(width: DoctorMetrics.chipGap),
            Flexible(child: _Chip(label: doctor.experienceLabel!)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accentSofter,
        borderRadius: AppRadius.allPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DoctorMetrics.chipPaddingH,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 7)],
            Flexible(
              child: Text(
                label,
                style: AppTypography.chipLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
