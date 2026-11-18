import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/dashboard.dart';
import '../../domain/pillar.dart';

/// Radar keseimbangan 4 Pilar Atribut. Nilai tiap sumbu = total XP pilar.
class PillarRadar extends StatelessWidget {
  const PillarRadar({super.key, required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final values = [
      for (final p in Pillar.values) (dashboard.pillarXp[p] ?? 0).toDouble(),
    ];
    // Skala sumbu mengikuti pilar tertinggi, minimal 100 XP (satu level).
    final scaleMax = math.max(100.0, values.reduce(math.max));

    return Semantics(
      label:
          'Radar pilar: ${[for (final p in Pillar.values) '${p.label} level ${dashboard.pillarLevel(p).level}'].join(', ')}',
      child: AspectRatio(
        aspectRatio: 1.25,
        child: RadarChart(
          RadarChartData(
            radarShape: RadarShape.polygon,
            tickCount: 3,
            ticksTextStyle: const TextStyle(
              color: Colors.transparent,
              fontSize: 1,
            ),
            tickBorderData: const BorderSide(color: Color(0xFF2A2F3A)),
            gridBorderData: const BorderSide(color: Color(0xFF2A2F3A)),
            radarBorderData: const BorderSide(color: Color(0xFF2A2F3A)),
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            titlePositionPercentageOffset: 0.16,
            titleTextStyle: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
            getTitle: (index, angle) =>
                RadarChartTitle(text: Pillar.values[index].label),
            dataSets: [
              // Set tak terlihat untuk mengunci skala sumbu dari 0..scaleMax.
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: Colors.transparent,
                entryRadius: 0,
                borderWidth: 0,
                dataEntries: [
                  const RadarEntry(value: 0),
                  for (var i = 1; i < Pillar.values.length; i++)
                    RadarEntry(value: scaleMax),
                ],
              ),
              RadarDataSet(
                fillColor: AppColors.primary.withValues(alpha: 0.28),
                borderColor: AppColors.primary,
                borderWidth: 2,
                entryRadius: 3,
                dataEntries: [for (final v in values) RadarEntry(value: v)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
