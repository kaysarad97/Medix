import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/doctor_photo.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/doctor.dart';
import '../providers/telemedicine_providers.dart';
import '../widgets/city_chip.dart';

enum _SortBy { rating, experience, price }

/// Результаты поиска врача по специальности/запросу.
///
/// Свёрстан по `design/Поиск врача результаты - Gold.png`. Фильтр «Близко к
/// Вам» переключается визуально, но не сортирует — координат пользователя и
/// клиник в моках нет.
///
/// Скидку и зачёркнутую цену показывает сервер, а не клиент: в ответе
/// каталога `price_for_user` и `discount_percent` посчитаны для того, кто
/// спрашивает. До 17 августа 2026 клиент гейтил показ по
/// `SubscriptionTier.gold` — и подписчик Silver видел полную цену, хотя
/// списывалась с него скидочная.
class DoctorSearchResultsScreen extends ConsumerStatefulWidget {
  const DoctorSearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<DoctorSearchResultsScreen> createState() =>
      _DoctorSearchResultsScreenState();
}

class _DoctorSearchResultsScreenState
    extends ConsumerState<DoctorSearchResultsScreen> {
  late final TextEditingController _controller;
  late String _query;
  _SortBy _sortBy = _SortBy.rating;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Doctor> _sorted(List<Doctor> doctors) {
    final sorted = [...doctors];
    switch (_sortBy) {
      case _SortBy.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortBy.experience:
        // Врачи без стажа уходят вниз: бэкенд его не хранит, и пустое
        // значение — «не знаем», а не «ноль лет».
        sorted.sort(
          (a, b) =>
              (b.experienceYears ?? -1).compareTo(a.experienceYears ?? -1),
        );
      case _SortBy.price:
        sorted.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final results =
        ref.watch(doctorSearchResultsProvider(_query)).value ?? const [];
    final sorted = _sorted(results);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                controller: _controller,
                onSubmit: (query) => setState(() => _query = query),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.searchResultsCount(results.length),
                style: AppTypography.cardItemMeta,
              ),
              const SizedBox(height: 12),
              _FilterChips(
                selected: _sortBy,
                onSelect: (value) => setState(() => _sortBy = value),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: sorted.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doctor = sorted[index];
                    return _ResultCard(
                      doctor: doctor,
                      isTopMatch: index == 0 && _sortBy == _SortBy.rating,
                      onTap: () => context.push(Routes.doctorOf(doctor.id)),
                    );
                  },
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
  const _SearchField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
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
                  controller: controller,
                  onSubmitted: onSubmit,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  cursorColor: AppColors.accent,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelect});

  final _SortBy selected;
  final ValueChanged<_SortBy> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      _SortBy.rating: l10n.sortByRating,
      _SortBy.experience: l10n.sortByExperience,
      _SortBy.price: l10n.sortByPrice,
    };
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == labels.length) {
            // «Близко к Вам» — визуальный чип без сортировки, геоданных нет.
            return _Chip(label: l10n.nearbyFilterChip, active: false);
          }
          final entry = labels.entries.elementAt(index);
          return _Chip(
            label: entry.value,
            active: entry.key == selected,
            onTap: () => onSelect(entry.key),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primaryBright : AppColors.surfaceWhite,
      borderRadius: AppRadius.allPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: AppTypography.chipLabel.copyWith(
                color: active ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.doctor,
    required this.isTopMatch,
    required this.onTap,
  });

  final Doctor doctor;
  final bool isTopMatch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isTopMatch ? AppColors.accentSofter : AppColors.surfaceWhite,
      borderRadius: AppRadius.allMd,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Photo(doctor: doctor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (doctor.clinic != null) ...[
                      Text(
                        doctor.clinic!,
                        style: AppTypography.doctorClinic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      doctor.fullName,
                      style: AppTypography.cardItemTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: AppTypography.doctorClinic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const AppIcon(
                          icon: MedixIcon.star,
                          size: 14,
                          color: AppColors.primaryBright,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.ratingLabel,
                          style: AppTypography.chipLabel,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.reviewsCountLabel(doctor.reviewsCount),
                            style: AppTypography.cardItemMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (doctor.experienceLabel != null)
                      Text(
                        doctor.experienceLabel!,
                        style: AppTypography.cardItemMeta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 96,
                child: _Price(doctor: doctor, isTopMatch: isTopMatch),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.doctor});

  final Doctor doctor;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    // Под портретом — та же подложка, что стояла на месте фотографии:
    // accentSoft, а не accentSofter, потому что на подсвеченной топ-карточке
    // фон уже accentSofter и тем же цветом кружок сливался бы с ним. Видна
    // она теперь только по краям выреза.
    return SizedBox(
      width: _size,
      height: _size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.accentSoft,
          shape: BoxShape.circle,
        ),
        child: DoctorPhoto(seed: doctor.id, url: doctor.photoUrl),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.doctor, required this.isTopMatch});

  final Doctor doctor;
  final bool isTopMatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Скидку и её обоснование считает сервер: зачёркнутая цена приходит
    // только тому, кому скидка положена.
    final hasDiscount = doctor.priceBeforeDiscountLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isTopMatch)
          Text(
            l10n.topMatchLabel,
            style: AppTypography.cardItemMeta,
            textAlign: TextAlign.right,
          ),
        if (hasDiscount)
          Text(
            '${doctor.priceBeforeDiscountLabel} ₸',
            style: AppTypography.cardItemMeta.copyWith(
              decoration: TextDecoration.lineThrough,
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.right,
          ),
        Text(
          '${doctor.priceLabel} ₸',
          style: AppTypography.cardItemTitle,
          textAlign: TextAlign.right,
        ),
        Text(
          l10n.perConsultationLabel,
          style: AppTypography.cardItemMeta,
          textAlign: TextAlign.right,
        ),
        if (hasDiscount)
          Text(
            l10n.forSubscribersLabel,
            style: AppTypography.goldLabel.copyWith(fontSize: 11),
            textAlign: TextAlign.right,
          ),
      ],
    );
  }
}
