import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dashboard.dart';
import '../../data/db/database.dart';
import '../../data/providers.dart';
import '../../domain/streak_calculator.dart';
import '../habit_form/habit_form_sheet.dart';
import '../stats/contribution_heatmap.dart';
import '../stats/stats_screen.dart';
import 'mastery_bar.dart';

class HabitDetailScreen extends ConsumerWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final int habitId;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus permanen?'),
        content: Text(
          '"${view.habit.name}" beserta seluruh riwayat dan XP-nya akan dihapus. '
          'Tindakan ini tidak bisa dibatalkan. Arsipkan saja jika ingin XP tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final actions = ref.read(habitActionsProvider);
    Navigator.of(context).pop();
    await actions.delete(habitId);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(habitActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    await actions.archive(habitId);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Kebiasaan diarsipkan. XP tetap tersimpan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(dashboardProvider).value?.habitById(habitId);
    final today = ref.watch(todayProvider);

    if (view == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }

    final habit = view.habit;
    final streak = view.streak;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => showHabitFormSheet(context, habit: habit),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Ubah',
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi lain',
            onSelected: (value) => switch (value) {
              'archive' => _archive(context, ref),
              _ => _confirmDelete(context, ref, view),
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'archive', child: Text('Arsipkan')),
              PopupMenuItem(value: 'delete', child: Text('Hapus permanen')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      habit.pillar.icon,
                      size: 16,
                      color: habit.pillar.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${habit.pillar.label} · ${habit.frequency.label}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  value: '${streak.current}',
                  label: 'Streak (${streak.unit})',
                  color: AppColors.streak,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${streak.best}',
                  label: 'Terbaik (${streak.unit})',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  value: '${view.doneDays.length}',
                  label: 'Total selesai',
                  color: AppColors.reward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: '66-Day Habit Mastery',
            child: MasteryBar(mastery: view.mastery),
          ),
          const SizedBox(height: 12),
          _ShieldCard(view: view),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Riwayat',
            child: ContributionHeatmap(
              counts: {for (final d in view.doneDays) d: 1},
              today: today,
              weeks: 26,
              color: habit.pillar.color,
            ),
          ),
          if (view.doneToday) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(habitActionsProvider).undo(habitId),
              icon: const Icon(Icons.undo_rounded),
              label: const Text('Batalkan penyelesaian hari ini'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShieldCard extends StatelessWidget {
  const _ShieldCard({required this.view});

  final HabitView view;

  @override
  Widget build(BuildContext context) {
    final streak = view.streak;
    final active = streak.shieldActive && !view.doneToday;
    final period = streak.isWeekly ? 'minggu' : 'hari';

    final (Color color, String title, String body) = active
        ? (
            AppColors.shield,
            'Shield aktif',
            'Kamu melewatkan satu $period, dan shield menjaga streak-mu. '
                'Selesaikan $period ini — melewatkannya lagi akan memutus streak.',
          )
        : streak.shieldReady
        ? (
            AppColors.shield,
            'Shield siap',
            'Jika satu $period terlewat, streak-mu tetap aman. Jangan sampai terlewat dua kali.',
          )
        : (
            AppColors.textMuted,
            'Shield mengisi ulang',
            'Selesaikan ${shieldRechargeCompletions - streak.shieldCharge} kali lagi untuk mengisi penuh.',
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active
            ? Color.alphaBlend(
                AppColors.shield.withValues(alpha: 0.1),
                AppColors.surface,
              )
            : AppColors.surface,
        borderRadius: AppRadius.borderRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            streak.shieldReady || active
                ? Icons.shield_rounded
                : Icons.shield_outlined,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Momentum Shield · $title',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!streak.shieldReady)
                      Text(
                        '${streak.shieldCharge}/$shieldRechargeCompletions',
                        style: monoStyle(size: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
