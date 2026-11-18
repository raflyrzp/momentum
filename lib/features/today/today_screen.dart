import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/day.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dashboard.dart';
import '../../data/providers.dart';
import '../../services/home_widget_service.dart';
import '../habit_detail/habit_detail_screen.dart';
import '../habit_form/habit_form_sheet.dart';
import 'habit_card.dart';
import 'reward_sheet.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    HabitView view,
  ) async {
    // Umpan balik sensorik langsung, tanpa menunggu penulisan database.
    HapticFeedback.mediumImpact();
    final actions = ref.read(habitActionsProvider);
    final messenger = ScaffoldMessenger.of(context);

    final result = await actions.complete(view.habit.id);
    if (result == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('+${result.xp} XP · ${result.habit.pillar.label}'),
          // Snackbar beraksi tidak hilang sendiri secara default.
          persist: false,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => actions.undo(view.habit.id),
          ),
        ),
      );

    if (context.mounted && (result.drop.isDrop || result.leveledUp)) {
      await showRewardSheet(context, result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHabitFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Kebiasaan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: dashboard.when(
          // Pertahankan tampilan (dan animasi kartu) saat data dimuat ulang.
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Gagal memuat data.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (data) {
            final habits = data.todayHabits;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(data: data)),
                if (habits.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(hasHabits: data.habits.isNotEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
                    sliver: SliverList.separated(
                      itemCount: habits.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final view = habits[index];
                        return HabitCard(
                              key: ValueKey(view.habit.id),
                              view: view,
                              onComplete: () => _complete(context, ref, view),
                              onOpen: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      HabitDetailScreen(habitId: view.habit.id),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 250.ms, delay: (40 * index).ms)
                            .slideY(begin: 0.08, curve: Curves.easeOut);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = data.level;
    final total = data.todayHabits.length;
    final offset = ref.watch(dayOffsetProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatLongDate(data.today),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Hari Ini',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              if (kDebugMode) _DebugMenu(offset: offset),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderRadius,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'LV ${level.level}',
                      style: monoStyle(size: 22, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${level.xpIntoLevel}',
                      style: monoStyle(size: 13, color: AppColors.reward),
                    ),
                    Text(
                      ' / ${level.xpForLevel} XP',
                      style: monoStyle(size: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: level.progress),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceHigh,
                      color: AppColors.reward,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.doneTodayCount}/$total',
                      style: monoStyle(size: 13),
                    ),
                    const Text(
                      ' selesai hari ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasHabits});

  final bool hasHabits;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasHabits ? Icons.self_improvement_rounded : Icons.bolt_rounded,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasHabits ? 'Tidak ada jadwal hari ini' : 'Mulai bangun momentum',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            hasHabits
                ? 'Nikmati hari pemulihanmu. Kebiasaan berikutnya muncul sesuai jadwal.'
                : 'Tambahkan kebiasaan pertamamu, lalu tahan tombolnya setiap kali selesai untuk mengumpulkan XP.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hanya ada di build debug: menggeser "hari ini" untuk menguji streak dan
/// shield, serta mengirim notifikasi uji.
class _DebugMenu extends ConsumerWidget {
  const _DebugMenu({required this.offset});

  final int offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Menu debug',
      icon: Badge(
        isLabelVisible: offset != 0,
        label: Text(offset > 0 ? '+$offset' : '$offset'),
        child: const Icon(
          Icons.bug_report_outlined,
          color: AppColors.textMuted,
        ),
      ),
      onSelected: (value) {
        final notifier = ref.read(dayOffsetProvider.notifier);
        switch (value) {
          case 'next':
            notifier.shift(1);
          case 'prev':
            notifier.shift(-1);
          case 'reset':
            notifier.reset();
          case 'notify':
            ref.read(notificationServiceProvider).showTest();
          case 'pin':
            requestPinHomeWidget();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'next', child: Text('Maju 1 hari')),
        PopupMenuItem(value: 'prev', child: Text('Mundur 1 hari')),
        PopupMenuItem(value: 'reset', child: Text('Kembali ke hari ini')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'notify', child: Text('Tes notifikasi')),
        PopupMenuItem(value: 'pin', child: Text('Pasang widget')),
      ],
    );
  }
}
