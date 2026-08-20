import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import 'doctor_analytics_metrics.dart';

/// Ломаная записей по дням месяца — «Аналитика Работы.png».
///
/// Подписи оси стоят не под каждым днём: в макете их семь — 1, 5, 10, 15,
/// 20, 25 и 30. Сама ломаная строится по всем значениям, подписи только
/// размечают ось.
class DoctorMonthLineChart extends StatelessWidget {
  const DoctorMonthLineChart({super.key, required this.perDay});

  final List<int> perDay;

  static const List<int> axisDays = [1, 5, 10, 15, 20, 25, 30];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: AppRadius.allMd,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: DoctorAnalyticsMetrics.lineChartHeight,
              child: CustomPaint(
                painter: _LinePainter(perDay),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final day in axisDays)
                  Text('$day', style: AppTypography.tileSubtitle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final max = values.fold(0, (m, v) => v > m ? v : m);
    final scale = max == 0 ? 1 : max;
    final step = size.width / (values.length - 1);

    final path = Path();
    for (final (index, value) in values.indexed) {
      // Ноль лежит на нижней кромке, максимум — на верхней.
      final point = Offset(
        index * step,
        size.height - size.height * (value / scale),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = AppColors.brandIndigo,
    );
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) => oldDelegate.values != values;
}
