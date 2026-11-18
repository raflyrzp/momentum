import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/mastery.dart';

/// Bilah evolusi 66-Day Habit Mastery dengan tiga fase.
class MasteryBar extends StatelessWidget {
  const MasteryBar({super.key, required this.mastery});

  final Mastery mastery;

  static Color colorOf(MasteryPhase phase) => switch (phase) {
    MasteryPhase.fragile => AppColors.streak,
    MasteryPhase.building => AppColors.primary,
    MasteryPhase.forged => AppColors.reward,
  };

  @override
  Widget build(BuildContext context) {
    final phase = mastery.phase;
    final color = colorOf(phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              phase.label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            Text('${mastery.daysDone}', style: monoStyle(size: 16)),
            Text(
              ' / $masteryTargetDays hari',
              style: monoStyle(size: 13, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          phase.description,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 14),
        Semantics(
          label:
              'Progres mastery ${(mastery.progress * 100).round()} persen, fase ${phase.label}',
          child: Row(
            children: [
              for (final p in MasteryPhase.values.take(2)) ...[
                Expanded(
                  flex: p.toDay! - p.fromDay + 1,
                  child: _Segment(
                    fill:
                        ((mastery.daysDone - p.fromDay + 1) /
                                (p.toDay! - p.fromDay + 1))
                            .clamp(0.0, 1.0),
                    color: colorOf(p),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.verified_rounded,
                size: 20,
                color: phase == MasteryPhase.forged
                    ? AppColors.reward
                    : AppColors.surfaceHigh,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              flex: 21,
              child: Text('Fragile', style: _phaseLabel),
            ),
            const Expanded(
              flex: 44,
              child: Text('Building', style: _phaseLabel),
            ),
            Text('Forged', style: _phaseLabel),
          ],
        ),
      ],
    );
  }
}

const _phaseLabel = TextStyle(fontSize: 11, color: AppColors.textMuted);

class _Segment extends StatelessWidget {
  const _Segment({required this.fill, required this.color});

  final double fill;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fill,
        minHeight: 8,
        backgroundColor: AppColors.surfaceHigh,
        color: color,
      ),
    );
  }
}
