import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Заглушка главной. Вёрстка по `design/Главная.png` — следующая задача.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Как Ваше здоровье\nсегодня?',
                textAlign: TextAlign.center,
                style: AppTypography.h1,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Экран в работе — вёрстка по design/Главная.png',
                textAlign: TextAlign.center,
                style: AppTypography.captionMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
