import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/doctor_specialty.dart';
import '../../../../shared/models/my_doctor.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/city_chip.dart';

/// Поиск врача: «Мои Врачи» и грид специальностей.
///
/// Свёрстан по `design/Поиск врача - спецализация.png`. Точных замеров нет
/// (макет — не 1:1 экспорт, а device-framed скриншот) — отступы взяты по
/// общей сетке приложения (20/16/12), без привязки к пикселю.
class DoctorSearchScreen extends ConsumerWidget {
  const DoctorSearchScreen({super.key});

  static const double _screenH = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(doctorSpecialtiesProvider).value ?? const [];
    final myDoctors = ref.watch(myDoctorsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _screenH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              ScreenTopBar(
                title: l10n.doctorSearchTitle,
                onBack: () => context.pop(),
                trailing: const CityChip(city: 'Алматы'),
              ),
              const SizedBox(height: 17),
              _SearchField(
                onSubmit: (query) =>
                    context.push(Routes.doctorSearchResultsOf(query)),
              ),
              const SizedBox(height: 20),
              if (myDoctors.isNotEmpty) ...[
                _SectionTitle(title: l10n.myDoctorsTitle, onSeeAll: () {}),
                const SizedBox(height: 12),
                _MyDoctorsList(doctors: myDoctors),
                const SizedBox(height: 20),
              ],
              _SectionTitle(
                title: l10n.allDoctorsTitle,
                trailing: const _SortIcon(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _SpecialtiesGrid(
                    specialties: specialties,
                    onTap: (specialty) => context.push(
                      Routes.doctorSearchResultsOf(specialty.title),
                    ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onSubmit});

  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 54,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allPill,
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            const AppIcon(icon: MedixIcon.search, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Center(
                child: TextField(
                  onSubmitted: onSubmit,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.doctorSearchHint,
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onSeeAll, this.trailing});

  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(title, style: AppTypography.sectionTitle),
        ?trailing,
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Text(
              AppLocalizations.of(context)!.viewAllLabel,
              style: AppTypography.linkSmall,
            ),
          ),
      ],
    );
  }
}

class _SortIcon extends StatelessWidget {
  const _SortIcon();

  @override
  Widget build(BuildContext context) {
    return const AppIcon(
      icon: MedixIcon.sort,
      size: 20,
      color: AppColors.textSecondary,
    );
  }
}

class _MyDoctorsList extends StatelessWidget {
  const _MyDoctorsList({required this.doctors});

  final List<MyDoctor> doctors;

  static const double _height = 60;
  static const double _cardWidth = 130;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: doctors.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return SizedBox(
            width: _cardWidth,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: AppRadius.allMd,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctor.specialty, style: AppTypography.cardItemTitle),
                    const SizedBox(height: 2),
                    Text(doctor.fullName, style: AppTypography.cardItemMeta),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpecialtiesGrid extends StatelessWidget {
  const _SpecialtiesGrid({required this.specialties, required this.onTap});

  final List<DoctorSpecialty> specialties;
  final ValueChanged<DoctorSpecialty> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: specialties.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final specialty = specialties[index];
        return _SpecialtyTile(
          specialty: specialty,
          onTap: () => onTap(specialty),
        );
      },
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  const _SpecialtyTile({required this.specialty, this.onTap});

  final DoctorSpecialty specialty;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                AppLocalizations.of(
                  context,
                )!.specialtyDoctorCount(specialty.doctorCount),
                style: AppTypography.cardItemMeta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
