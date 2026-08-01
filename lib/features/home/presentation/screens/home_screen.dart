import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/icon_chip.dart';
import '../providers/home_providers.dart';
import '../widgets/doctors_card.dart';
import '../widgets/home_header.dart';
import '../widgets/home_metrics.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/upcoming_appointments_card.dart';
import '../widgets/upload_analyses_card.dart';

/// Главный экран.
///
/// Свёрстан по `design/Главная.png` (440×1299 — макет прокручиваемый).
///
/// Блок «Видео-инструкция» из макета не перенесён: там карточка приглушена,
/// а заголовок перечёркнут насквозь — похоже на пометку дизайнера об отмене.
/// TODO(design): подтвердить. Если блок нужен, он устроен так же, как
/// [UploadAnalysesCard], и добавляется одной строкой.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialties = ref.watch(specialtiesProvider);
    final appointments = ref.watch(upcomingAppointmentsProvider);

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: HomeMetrics.headerTop),
              const HomeHeader(unreadCount: 2),
              const SizedBox(height: HomeMetrics.headerToGreeting),
              _Section(
                child: Text(
                  'Как Ваше здоровье сегодня?',
                  style: AppTypography.homeGreeting,
                ),
              ),
              const SizedBox(height: HomeMetrics.greetingToSearch),
              const _SymptomSearchField(),
              const SizedBox(height: HomeMetrics.searchToActions),
              const _Section(child: QuickActionsCard()),
              const SizedBox(height: HomeMetrics.cardGap),
              _Section(
                child: DoctorsCard(specialties: specialties.value ?? const []),
              ),
              const SizedBox(height: HomeMetrics.cardGap),
              const _Section(child: UploadAnalysesCard()),
              const SizedBox(height: HomeMetrics.cardGap),
              _Section(
                child: UpcomingAppointmentsCard(
                  appointments: appointments.value ?? const [],
                ),
              ),
              const SizedBox(height: HomeMetrics.cardGap),
            ],
          ),
        ),
      ),
    );
  }
}

/// Общие горизонтальные поля карточек.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: HomeMetrics.screenH),
      child: child,
    );
  }
}

class _SymptomSearchField extends StatelessWidget {
  const _SymptomSearchField();

  @override
  Widget build(BuildContext context) {
    return _Section(
      child: SizedBox(
        height: HomeMetrics.searchHeight,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allPill,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const AppIconChip(
                icon: MedixIcon.symptomSearch,
                size: 32,
                background: Colors.transparent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: TextField(
                    style: AppTypography.bodyLg.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    cursorColor: AppColors.accent,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Опишите Ваши симптомы...',
                      hintStyle: AppTypography.placeholder,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }
}
