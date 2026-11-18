import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/habit_repository.dart';
import '../../domain/drop_roller.dart';

/// Lembar hadiah untuk Critical Focus Drop dan/atau kenaikan level pilar.
Future<void> showRewardSheet(BuildContext context, CompletionResult result) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _RewardSheet(result: result),
  );
}

class _RewardSheet extends StatelessWidget {
  const _RewardSheet({required this.result});

  final CompletionResult result;

  @override
  Widget build(BuildContext context) {
    final drop = result.drop;
    final pillar = result.habit.pillar;

    final (
      IconData icon,
      Color color,
      String title,
      String body,
    ) = switch (drop.type) {
      DropType.bonusXp => (
        Icons.auto_awesome_rounded,
        AppColors.reward,
        'Critical Focus Drop',
        'Bonus fokus untuk ${pillar.label}.',
      ),
      DropType.insight => (
        Icons.lightbulb_rounded,
        AppColors.streak,
        'Critical Focus Drop',
        drop.insight ?? '',
      ),
      DropType.badgeFragment => (
        Icons.diamond_rounded,
        AppColors.shield,
        'Fragmen badge langka',
        'Kumpulkan $fragmentsPerBadge fragmen untuk membentuk satu badge.',
      ),
      DropType.none => (
        pillar.icon,
        pillar.color,
        'Level naik',
        '${pillar.label} kini level ${result.pillarLevelAfter}.',
      ),
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 34),
                )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                )
                .shimmer(delay: 350.ms, duration: 900.ms),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            if (drop.type == DropType.bonusXp) ...[
              const SizedBox(height: 8),
              Text(
                '+${drop.bonusXp} XP',
                style: monoStyle(
                  size: 28,
                  weight: FontWeight.w700,
                  color: AppColors.reward,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            if (drop.isDrop && result.leveledUp) ...[
              const SizedBox(height: 12),
              Text(
                '${pillar.label} naik ke level ${result.pillarLevelAfter}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: pillar.color,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }
}
