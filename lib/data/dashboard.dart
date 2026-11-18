import '../core/day.dart';
import '../domain/drop_roller.dart';
import '../domain/mastery.dart';
import '../domain/pillar.dart';
import '../domain/streak_calculator.dart';
import '../domain/xp_engine.dart';
import 'db/database.dart';

/// Kebiasaan beserta semua status turunannya untuk satu hari.
class HabitView {
  const HabitView({
    required this.habit,
    required this.streak,
    required this.doneToday,
    required this.scheduledToday,
    required this.doneThisWeek,
    required this.doneDays,
  });

  final Habit habit;
  final StreakInfo streak;
  final bool doneToday;
  final bool scheduledToday;
  final int doneThisWeek;
  final Set<int> doneDays;

  Mastery get mastery => Mastery(doneDays.length);
}

class Dashboard {
  const Dashboard({
    required this.today,
    required this.habits,
    required this.pillarXp,
    required this.heatmap,
    required this.fragments,
  });

  final DateTime today;

  /// Kebiasaan aktif (tidak diarsipkan).
  final List<HabitView> habits;
  final Map<Pillar, int> pillarXp;

  /// dayKey → jumlah kebiasaan yang diselesaikan hari itu.
  final Map<int, int> heatmap;
  final int fragments;

  List<HabitView> get todayHabits =>
      habits.where((h) => h.scheduledToday).toList();

  int get doneTodayCount => todayHabits.where((h) => h.doneToday).length;

  int get totalXp => pillarXp.values.fold(0, (a, b) => a + b);

  LevelInfo get level => LevelInfo.fromXp(totalXp);

  LevelInfo pillarLevel(Pillar p) => LevelInfo.fromXp(pillarXp[p] ?? 0);

  int get badges => fragments ~/ fragmentsPerBadge;

  HabitView? habitById(int id) {
    for (final h in habits) {
      if (h.habit.id == id) return h;
    }
    return null;
  }
}

/// Menurunkan seluruh status tampilan dari data mentah. XP dari kebiasaan yang
/// diarsipkan tetap dihitung.
Dashboard buildDashboard({
  required List<Habit> habits,
  required List<Completion> completions,
  required DateTime today,
}) {
  today = dateOnly(today);
  final todayKey = dayKey(today);
  final week = weekStart(today);

  final pillarOf = {for (final h in habits) h.id: h.pillar};
  final pillarXp = {for (final p in Pillar.values) p: 0};
  final heatmap = <int, int>{};
  final doneByHabit = <int, Set<int>>{};
  var fragments = 0;

  for (final c in completions) {
    final pillar = pillarOf[c.habitId];
    if (pillar == null) continue;
    pillarXp[pillar] = pillarXp[pillar]! + c.xp + c.bonusXp;
    heatmap[c.day] = (heatmap[c.day] ?? 0) + 1;
    doneByHabit.putIfAbsent(c.habitId, () => {}).add(c.day);
    if (c.dropType == DropType.badgeFragment) fragments++;
  }

  final views = <HabitView>[];
  for (final h in habits) {
    if (h.archivedAt != null) continue;
    final done = doneByHabit[h.id] ?? const <int>{};
    var doneThisWeek = 0;
    for (var i = 0; i < 7; i++) {
      if (done.contains(dayKey(addDays(week, i)))) doneThisWeek++;
    }
    views.add(
      HabitView(
        habit: h,
        streak: calculateStreak(
          doneDays: done,
          frequency: h.frequency,
          startDay: h.createdAt.toLocal(),
          today: today,
        ),
        doneToday: done.contains(todayKey),
        scheduledToday: h.frequency.isScheduledOn(today),
        doneThisWeek: doneThisWeek,
        doneDays: done,
      ),
    );
  }

  return Dashboard(
    today: today,
    habits: views,
    pillarXp: pillarXp,
    heatmap: heatmap,
    fragments: fragments,
  );
}
