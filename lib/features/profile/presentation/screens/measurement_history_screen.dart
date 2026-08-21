import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/screen_top_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/medical_card.dart';
import '../providers/profile_providers.dart';

enum MeasurementHistoryPeriod {
  month(days: 30, label: '30'),
  quarter(days: 90, label: '90'),
  year(days: 365, label: '365');

  const MeasurementHistoryPeriod({required this.days, required this.label});

  final int days;
  final String label;
}

/// История роста или веса.
///
/// Отдельного макета дизайнер не присылал. Экран использует существующие
/// токены мед-карты и не вводит новую визуальную систему. Даты диапазона
/// отправляются в API, поэтому переключатель не фильтрует уже загруженный
/// список локально.
class MeasurementHistoryScreen extends ConsumerStatefulWidget {
  const MeasurementHistoryScreen({
    super.key,
    required this.kind,
    this.familyMemberId,
    this.now,
  });

  final MeasurementKind kind;
  final String? familyMemberId;
  final DateTime? now;

  @override
  ConsumerState<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState
    extends ConsumerState<MeasurementHistoryScreen> {
  MeasurementHistoryPeriod period = MeasurementHistoryPeriod.month;

  MeasurementHistoryQuery get query {
    final to = widget.now ?? DateTime.now().toUtc();
    return (
      kind: widget.kind,
      familyMemberId: widget.familyMemberId,
      from: to.subtract(Duration(days: period.days)),
      to: to,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.kind == MeasurementKind.height
        ? l10n.heightFieldLabel
        : l10n.weightFieldLabel;
    final history = ref.watch(measurementHistoryProvider(query));

    return AppScaffold(
      background: AppBackgroundStyle.main,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 36),
            ScreenTopBar(
              title: title,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _PeriodSelector(
                selected: period,
                onSelected: (value) => setState(() => period = value),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: history.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: IconButton(
                      tooltip: 'Retry',
                      onPressed: () =>
                          ref.invalidate(measurementHistoryProvider(query)),
                      icon: const Icon(Icons.refresh),
                      color: AppColors.primaryBright,
                    ),
                  ),
                  data: (points) => points.isEmpty
                      ? Center(
                          child: Text(
                            l10n.emptyResultsLabel,
                            style: AppTypography.bodyMd,
                          ),
                        )
                      : _HistoryContent(points: points),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelected});

  final MeasurementHistoryPeriod selected;
  final ValueChanged<MeasurementHistoryPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceToggle,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        children: MeasurementHistoryPeriod.values.map((value) {
          final active = value == selected;
          return Expanded(
            child: Semantics(
              selected: active,
              button: true,
              label: '${value.label} days',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(value),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? AppColors.surfaceWhite : Colors.transparent,
                    borderRadius: AppRadius.allPill,
                  ),
                  child: Text(
                    '${value.label} дн.',
                    style: AppTypography.chipLabel.copyWith(
                      color: active
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({required this.points});

  final List<MeasurementPoint> points;

  @override
  Widget build(BuildContext context) {
    final sorted = [...points]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final latest = sorted.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.all(Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatValue(latest.value)} ${latest.unit}',
                  style: AppTypography.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 210,
                  child: CustomPaint(
                    key: const Key('measurement-history-chart'),
                    painter: _HistoryChartPainter(sorted),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final point = sorted[sorted.length - 1 - index];
              return DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: AppRadius.allPill,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(point.measuredAt),
                          style: AppTypography.bodyMd,
                        ),
                      ),
                      Text(
                        '${_formatValue(point.value)} ${point.unit}',
                        style: AppTypography.chipLabel.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatValue(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

class _HistoryChartPainter extends CustomPainter {
  const _HistoryChartPainter(this.points);

  final List<MeasurementPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var row = 0; row <= 4; row++) {
      final y = size.height * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final values = points.map((point) => point.value);
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final spread = math.max(high - low, 1).toDouble();
    final path = Path();
    final offsets = <Offset>[];
    for (var index = 0; index < points.length; index++) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / (points.length - 1);
      final y =
          size.height - ((points[index].value - low) / spread * size.height);
      final point = Offset(x, y.clamp(4, size.height - 4));
      offsets.add(point);
      index == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primaryBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = AppColors.primary;
    for (final point in offsets) {
      canvas.drawCircle(point, 4, dot);
    }
  }

  @override
  bool shouldRepaint(_HistoryChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
