import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/my_doctor.dart';
import 'profile_metrics.dart';

/// «Мои Врачи» — заголовок со ссылкой «Все» и горизонтальная карусель тех,
/// у кого пользователь уже был.
///
/// Карусель, как и на главной, намеренно выходит за правое поле карточки:
/// обрезанная третья карточка подсказывает, что список листается.
class MyDoctorsCard extends StatelessWidget {
  const MyDoctorsCard({
    super.key,
    required this.doctors,
    required this.title,
    this.onSeeAll,
    this.onDoctorTap,
  });

  final List<MyDoctor> doctors;

  /// «Мои Врачи» у пользователя, «Врачи моего ребёнка» / «Врачи для
  /// старших» на карточке члена семьи — см. `design/Моя Семья Ребенок.png`.
  /// Локализованное значение всегда приходит от вызывающей стороны: у
  /// `BuildContext` внутри виджета нет доступа к тому, каким текстом его
  /// вызвали как значение по умолчанию.
  final String title;

  final VoidCallback? onSeeAll;
  final ValueChanged<MyDoctor>? onDoctorTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: ProfileMetrics.allRadius,
      padding: const EdgeInsets.fromLTRB(
        ProfileMetrics.cardPadding,
        ProfileMetrics.cardPadding,
        0,
        ProfileMetrics.cardPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: ProfileMetrics.cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: AppTypography.sectionTitle),
                GestureDetector(
                  onTap: onSeeAll,
                  child: Text(
                    AppLocalizations.of(context)!.viewAllLabel,
                    style: AppTypography.linkSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ProfileMetrics.doctorsTitleToList),
          SizedBox(
            height: ProfileMetrics.doctorCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: doctors.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: ProfileMetrics.doctorCardGap),
              itemBuilder: (context, index) => _DoctorCard(
                doctor: doctors[index],
                onTap: () => onDoctorTap?.call(doctors[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor, this.onTap});

  final MyDoctor doctor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProfileMetrics.doctorCardWidth,
      child: Material(
        color: AppColors.surfaceWhite,
        borderRadius: ProfileMetrics.allRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _Photo(url: doctor.photoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        doctor.specialty,
                        style: AppTypography.bodyMd,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.fullName,
                        style: AppTypography.cardItemMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

/// Фотография врача — круглая, в отличие от вырезки на экране профиля врача.
class _Photo extends StatelessWidget {
  const _Photo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ProfileMetrics.doctorPhotoSize,
      height: ProfileMetrics.doctorPhotoSize,
      child: ClipOval(
        child: url == null
            ? const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.accentSofter),
              )
            : Image.network(url!, fit: BoxFit.cover),
      ),
    );
  }
}
