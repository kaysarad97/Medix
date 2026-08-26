import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/doctor_photo.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/doctor_specialty.dart';
import 'home_metrics.dart';

/// «Врачи» — заголовок со ссылкой «Все» и горизонтальная карусель
/// специальностей.
///
/// Карусель намеренно выходит за правое поле карточки: в макете третья
/// карточка обрезана краем, это подсказка, что список прокручивается.
class DoctorsCard extends StatelessWidget {
  const DoctorsCard({
    super.key,
    required this.specialties,
    this.onSeeAll,
    this.onSpecialtyTap,
  });

  final List<DoctorSpecialty> specialties;
  final VoidCallback? onSeeAll;
  final ValueChanged<DoctorSpecialty>? onSpecialtyTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              HomeMetrics.cardPadding + 3,
              HomeMetrics.cardPadding,
              HomeMetrics.cardPadding,
              0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(l10n.doctorsCardTitle, style: AppTypography.sectionTitle),
                GestureDetector(
                  onTap: onSeeAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    l10n.viewAllLabel,
                    style: AppTypography.linkSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: HomeMetrics.doctorsTitleToList),
          SizedBox(
            height: HomeMetrics.doctorCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: HomeMetrics.cardPadding),
              itemCount: specialties.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: HomeMetrics.doctorCardGap),
              itemBuilder: (context, index) {
                final specialty = specialties[index];
                return _SpecialtyCard(
                  specialty: specialty,
                  onTap: () => onSpecialtyTap?.call(specialty),
                );
              },
            ),
          ),
          const SizedBox(height: HomeMetrics.cardPadding),
        ],
      ),
    );
  }
}

class _SpecialtyCard extends StatelessWidget {
  const _SpecialtyCard({required this.specialty, this.onTap});

  final DoctorSpecialty specialty;
  final VoidCallback? onTap;

  /// Фотография занимает левую часть карточки.
  static const double _photoWidth = 55;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: HomeMetrics.doctorCardWidth,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              // Своей фотографии у специальности нет — берётся портрет из
              // набора дизайнера по её названию, чтобы у «Терапевта» на всех
              // экранах было одно и то же лицо.
              SizedBox(
                width: _photoWidth,
                child: DoctorPhoto(
                  seed: specialty.title,
                  url: specialty.photoUrl,
                  borderRadius: BorderRadius.zero,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty.title,
                        style: AppTypography.cardItemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.specialtyDoctorCount(specialty.doctorCount),
                        style: AppTypography.cardItemMeta,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
