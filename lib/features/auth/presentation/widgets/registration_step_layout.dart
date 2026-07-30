import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/step_progress_bar.dart';

/// Общая шапка шага регистрации: прогресс-бар и заголовок.
///
/// Замеры одинаковы на всех трёх макетах шагов: бар в 187…196, заголовок
/// прописными от 269, левое поле 20.
class RegistrationStepLayout extends StatelessWidget {
  const RegistrationStepLayout({
    super.key,
    required this.progress,
    required this.title,
    required this.children,
    this.barToTitle = defaultBarToTitle,
  });

  final double progress;
  final String title;

  /// Содержимое ниже заголовка — вместе с отступами, они на каждом шаге свои.
  final List<Widget> children;

  /// Отступ от бара до заголовка. На шагах с однострочным заголовком в
  /// макетах он один, на «Настройках приложения» заголовок стоит выше.
  final double barToTitle;

  /// Верх прогресс-бара — 187 при безопасной зоне 62.
  static const double _barTop = 125;

  /// Бар 187…196 → строка заголовка 261.
  static const double defaultBarToTitle = 64;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _barTop),
              Center(child: StepProgressBar(progress: progress)),
              SizedBox(height: barToTitle),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Text(title, style: AppTypography.h1),
              ),
              ...children,
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кнопка «Далее →» в габаритах макета: 330×55 по центру.
class RegistrationNextButton extends StatelessWidget {
  const RegistrationNextButton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(width: PrimaryButton.mediumWidth, child: child),
    );
  }
}

/// Общие габариты карточки-формы на шагах регистрации.
abstract final class RegistrationFormCard {
  /// Карточка 19…418 по горизонтали, поля 32…405 — по 13 с каждой стороны;
  /// сверху и снизу по 14.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(13, 14, 13, 14);

  /// Низ поля → верх следующего.
  static const double fieldGap = 14;
}
