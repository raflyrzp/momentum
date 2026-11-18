import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/dashboard.dart';
import '../../data/providers.dart';
import '../../domain/drop_roller.dart';
import '../../domain/pillar.dart';
import 'contribution_heatmap.dart';
import 'pillar_radar.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: dashboard.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Gagal memuat data.\n$error')),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Statistik',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
              ),
              _Summary(data: data),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Keseimbangan pilar',
                child: Column(
                  children: [
                    PillarRadar(dashboard: data),
                    const SizedBox(height: 8),
                    for (final p in Pillar.values)
                      _PillarRow(data: data, pillar: p),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'Aktivitas setahun',
                child: ContributionHeatmap(
                  counts: data.heatmap,
                  today: data.today,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.text,
    this.icon,
  });

  final String value;
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: monoStyle(
                      size: 22,
                      weight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              height: 1.3,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.data});

  final Dashboard data;

  @override
  Widget build(BuildContext context) {
    final best = data.habits.fold(
      0,
      (max, h) =>
          h.streak.isWeekly || h.streak.best < max ? max : h.streak.best,
    );
    final towardNext = data.fragments % fragmentsPerBadge;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatTile(
              value: 'LV ${data.level.level}',
              label: 'Level total',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              value: '$best',
              label: 'Streak terbaik',
              color: AppColors.streak,
              icon: Icons.local_fire_department_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              value: '${data.badges}',
              label: 'Badge · fragmen $towardNext/$fragmentsPerBadge',
              color: AppColors.shield,
              icon: Icons.diamond_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarRow extends StatelessWidget {
  const _PillarRow({required this.data, required this.pillar});

  final Dashboard data;
  final Pillar pillar;

  @override
  Widget build(BuildContext context) {
    final level = data.pillarLevel(pillar);

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(pillar.icon, size: 18, color: pillar.color),
              const SizedBox(width: 8),
              Text(
                pillar.label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '  ${pillar.subtitle}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              Text('LV ${level.level}', style: monoStyle(size: 13)),
              Text(
                '  ${level.xpIntoLevel}/${level.xpForLevel}',
                style: monoStyle(size: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: level.progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHigh,
              color: pillar.color,
            ),
          ),
        ],
      ),
    );
  }
}
