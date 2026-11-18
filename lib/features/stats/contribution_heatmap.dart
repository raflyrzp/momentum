import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/day.dart';
import '../../core/theme/app_colors.dart';

/// Heatmap kontribusi ala GitHub: kolom = minggu (Senin di atas), kolom
/// terakhir = minggu berjalan. Bisa digulir horizontal, dimulai dari hari ini.
class ContributionHeatmap extends StatelessWidget {
  const ContributionHeatmap({
    super.key,
    required this.counts,
    required this.today,
    this.weeks = 53,
    this.color = AppColors.reward,
  });

  /// dayKey → jumlah penyelesaian.
  final Map<int, int> counts;
  final DateTime today;
  final int weeks;
  final Color color;

  static const _cell = 13.0;
  static const _gap = 3.0;
  static const _labelHeight = 18.0;

  @override
  Widget build(BuildContext context) {
    final width = weeks * (_cell + _gap) - _gap;
    const height = _labelHeight + 7 * (_cell + _gap) - _gap;
    final total = counts.values.fold(0, (a, b) => a + b);

    return Semantics(
      label: 'Heatmap aktivitas $weeks minggu terakhir, $total penyelesaian',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: CustomPaint(
          size: Size(width, height),
          painter: _HeatmapPainter(
            counts: counts,
            today: dateOnly(today),
            weeks: weeks,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.counts,
    required this.today,
    required this.weeks,
    required this.color,
  });

  final Map<int, int> counts;
  final DateTime today;
  final int weeks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = ContributionHeatmap._cell;
    const step = cell + ContributionHeatmap._gap;
    final firstWeek = addDays(weekStart(today), -7 * (weeks - 1));
    final maxCount = counts.values.fold(1, math.max);
    final paint = Paint();
    int? lastMonth;

    for (var w = 0; w < weeks; w++) {
      final monday = addDays(firstWeek, 7 * w);

      if (monday.month != lastMonth) {
        // Lewati label pertama bila terlalu dekat dengan label berikutnya.
        if (lastMonth != null || monday.day <= 14) {
          final label = TextPainter(
            text: TextSpan(
              text: monthShortNames[monday.month - 1],
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          label.paint(canvas, Offset(w * step, 0));
        }
        lastMonth = monday.month;
      }

      for (var d = 0; d < 7; d++) {
        final day = addDays(monday, d);
        if (day.isAfter(today)) break;
        final count = counts[dayKey(day)] ?? 0;
        paint.color = count == 0
            ? AppColors.surfaceHigh
            : color.withValues(alpha: 0.3 + 0.7 * (count / maxCount));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * step,
              ContributionHeatmap._labelHeight + d * step,
              cell,
              cell,
            ),
            const Radius.circular(3.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) =>
      old.counts != counts ||
      old.today != today ||
      old.weeks != weeks ||
      old.color != color;
}
