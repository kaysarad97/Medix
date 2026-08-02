import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../../domain/entities/user_profile.dart';
import 'profile_metrics.dart';
import 'section_header.dart';

/// Карточка «Мед-карта» на экране профиля: ИИН, три плитки с ростом, весом
/// и возрастом, место прописки.
///
/// Показывает то, что уже заполнено; правится на отдельном экране, куда
/// ведёт шеврон в заголовке.
class MedicalCardSummary extends StatelessWidget {
  const MedicalCardSummary({
    super.key,
    required this.profile,
    required this.now,
    this.onOpen,
  });

  final UserProfile profile;

  /// Сегодняшняя дата — возраст считается от неё. Передаётся снаружи, иначе
  /// виджет-тест начнёт зависеть от дня прогона.
  final DateTime now;

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: ProfileMetrics.allRadius,
      padding: const EdgeInsets.all(ProfileMetrics.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SectionHeader(
            icon: MedixIcon.medicalCard,
            title: 'Мед-карта',
            onTap: onOpen,
          ),
          const SizedBox(height: ProfileMetrics.headerToField),
          _Field(text: profile.iin, placeholder: 'ИИН'),
          const SizedBox(height: ProfileMetrics.fieldToTiles),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: MedixIcon.height,
                  label: 'Рост',
                  value: profile.heightLabel,
                ),
              ),
              const SizedBox(width: ProfileMetrics.tileGap),
              Expanded(
                child: _Tile(
                  icon: MedixIcon.weight,
                  label: 'Вес',
                  value: profile.weightLabel,
                ),
              ),
              const SizedBox(width: ProfileMetrics.tileGap),
              Expanded(
                child: _Tile(
                  icon: MedixIcon.age,
                  label: 'Возраст',
                  value: profile.ageLabel(now),
                ),
              ),
            ],
          ),
          const SizedBox(height: ProfileMetrics.tilesToField),
          _Field(
            text: profile.registrationAddress,
            placeholder: 'Место прописки',
          ),
        ],
      ),
    );
  }
}

/// Белое поле только для чтения. Пустое показывает подсказку, а не прочерк —
/// так в макете.
class _Field extends StatelessWidget {
  const _Field({required this.text, required this.placeholder});

  final String? text;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final filled = text != null && text!.isNotEmpty;
    return SizedBox(
      height: ProfileMetrics.fieldHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: AppRadius.allPill,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              filled ? text! : placeholder,
              style: filled
                  ? AppTypography.bodyMd
                  : AppTypography.placeholder.copyWith(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

/// Плитка «Рост / 176 см»: иконка с подписью сверху, синяя пилюля значения
/// снизу и шеврон в правом нижнем углу.
class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value});

  final MedixIcon icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProfileMetrics.tileHeight,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: ProfileMetrics.allRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(icon: icon, size: 18, color: AppColors.textPrimary),
                  const SizedBox(width: 6),
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
              const Spacer(),
              Row(
                children: [
                  Flexible(child: _ValuePill(value: value)),
                  const SizedBox(width: 6),
                  const AppIcon(
                    icon: MedixIcon.chevronRight,
                    size: 12,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: AppRadius.allPill,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          value,
          style: AppTypography.chipLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
