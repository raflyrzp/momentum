import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dashboard.dart';
import '../../data/db/database.dart';
import 'charge_button.dart';
import 'particle_burst.dart';

class HabitCard extends StatefulWidget {
  const HabitCard({
    super.key,
    required this.view,
    required this.onComplete,
    required this.onOpen,
  });

  final HabitView view;
  final VoidCallback onComplete;
  final VoidCallback onOpen;

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> {
  var _burst = 0;

  void _handleCharged() {
    setState(() => _burst++);
    widget.onComplete();
  }

  void _showHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Tahan tombol untuk menyelesaikan'),
          duration: Duration(milliseconds: 1400),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final habit = view.habit;
    final done = view.doneToday;
    final shielded = view.streak.shieldActive && !done;

    final background = done
        ? Color.alphaBlend(
            AppColors.reward.withValues(alpha: 0.14),
            AppColors.surface,
          )
        : shielded
        ? Color.alphaBlend(
            AppColors.shield.withValues(alpha: 0.08),
            AppColors.surface,
          )
        : AppColors.surface;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.borderRadius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: AppRadius.borderRadius,
              onTap: widget.onOpen,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: habit.pillar.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        habit.pillar.icon,
                        size: 20,
                        color: habit.pillar.color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? AppColors.text.withValues(alpha: 0.8)
                                  : AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MetaRow(view: view),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChargeButton(
                      done: done,
                      color: habit.pillar.color,
                      onCharged: _handleCharged,
                      onShortTap: _showHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ParticleBurst(
            trigger: _burst,
            origin: const Alignment(0.86, 0),
            color: AppColors.reward,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.view});

  final HabitView view;

  @override
  Widget build(BuildContext context) {
    final streak = view.streak;
    final frequency = view.habit.frequency;
    final streakColor = streak.current > 0
        ? AppColors.streak
        : AppColors.textMuted;

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16,
              color: streakColor,
            ),
            const SizedBox(width: 3),
            Text(
              '${streak.current}',
              style: monoStyle(size: 13, color: streakColor),
            ),
            Text(
              ' ${streak.unit}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        if (streak.shieldActive && !view.doneToday)
          const _Tag(
            icon: Icons.shield_rounded,
            label: 'Shield aktif',
            color: AppColors.shield,
          )
        else if (frequency.isWeekly)
          Text(
            '${view.doneThisWeek}/${frequency.timesPerWeek} minggu ini',
            style: monoStyle(size: 12, color: AppColors.textMuted),
          )
        else
          Text(
            frequency.label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
