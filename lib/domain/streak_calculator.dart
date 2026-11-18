import 'dart:math' as math;

import '../core/day.dart';
import 'frequency.dart';

/// Jumlah penyelesaian yang dibutuhkan untuk mengisi ulang Momentum Shield
/// setelah terpakai.
const shieldRechargeCompletions = 7;

class StreakInfo {
  const StreakInfo({
    required this.current,
    required this.best,
    required this.isWeekly,
    required this.shieldActive,
    required this.shieldReady,
    required this.shieldCharge,
  });

  static const empty = StreakInfo(
    current: 0,
    best: 0,
    isWeekly: false,
    shieldActive: false,
    shieldReady: true,
    shieldCharge: shieldRechargeCompletions,
  );

  /// Panjang streak saat ini, dalam hari atau minggu (lihat [isWeekly]).
  final int current;
  final int best;
  final bool isWeekly;

  /// Periode terakhir terlewat dan sedang dijembatani shield; periode berjalan
  /// belum diselesaikan. Melewatkannya lagi akan memutus streak.
  final bool shieldActive;

  /// Shield terisi penuh dan siap menjembatani satu periode terlewat.
  final bool shieldReady;

  /// 0..[shieldRechargeCompletions].
  final int shieldCharge;

  String get unit => isWeekly ? 'minggu' : 'hari';
}

/// Menghitung streak dan status Momentum Shield murni dari riwayat.
///
/// Aturan "Never Miss Twice": satu periode terjadwal yang terlewat dijembatani
/// bila (a) streak sedang berjalan, (b) periode sebelumnya tidak terlewat, dan
/// (c) shield terisi penuh. Shield terisi ulang setelah
/// [shieldRechargeCompletions] penyelesaian. Periode yang sedang berjalan
/// (hari ini / minggu ini) tidak pernah dihitung sebagai terlewat.
StreakInfo calculateStreak({
  required Set<int> doneDays,
  required Frequency frequency,
  required DateTime startDay,
  required DateTime today,
}) {
  today = dateOnly(today);
  startDay = dateOnly(startDay);
  if (doneDays.isNotEmpty) {
    final first = dayFromKey(doneDays.reduce(math.min));
    if (first.isBefore(startDay)) startDay = first;
  }
  if (startDay.isAfter(today)) startDay = today;

  final state = _ShieldState();

  if (frequency.isWeekly) {
    final currentWeek = weekStart(today);
    for (
      var week = weekStart(startDay);
      !week.isAfter(currentWeek);
      week = addDays(week, 7)
    ) {
      var count = 0;
      for (var i = 0; i < 7; i++) {
        if (doneDays.contains(dayKey(addDays(week, i)))) count++;
      }
      state.step(
        met: count >= frequency.timesPerWeek,
        completions: count,
        isCurrent: week == currentWeek,
      );
    }
  } else {
    for (var day = startDay; !day.isAfter(today); day = addDays(day, 1)) {
      if (!frequency.isScheduledOn(day)) continue;
      final done = doneDays.contains(dayKey(day));
      state.step(met: done, completions: done ? 1 : 0, isCurrent: day == today);
    }
  }

  return StreakInfo(
    current: state.streak,
    best: state.best,
    isWeekly: frequency.isWeekly,
    shieldActive: state.bridging,
    shieldReady: state.charge >= shieldRechargeCompletions,
    shieldCharge: state.charge,
  );
}

class _ShieldState {
  int streak = 0;
  int best = 0;
  int charge = shieldRechargeCompletions;

  /// Periode sebelumnya terlewat dan dijembatani shield.
  bool bridging = false;

  void step({
    required bool met,
    required int completions,
    required bool isCurrent,
  }) {
    final wasReady = charge >= shieldRechargeCompletions;
    charge = math.min(shieldRechargeCompletions, charge + completions);

    if (met) {
      streak++;
      best = math.max(best, streak);
      bridging = false;
    } else if (isCurrent) {
      // Periode berjalan belum selesai: belum dianggap terlewat.
    } else if (streak > 0 && !bridging && wasReady) {
      // Shield terpakai; penyelesaian parsial di periode ini tidak mengisi ulang.
      bridging = true;
      charge = 0;
    } else {
      streak = 0;
      bridging = false;
    }
  }
}
