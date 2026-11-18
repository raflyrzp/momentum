import 'dart:math';

import 'package:drift/drift.dart';

import '../core/day.dart';
import '../domain/drop_roller.dart';
import '../domain/frequency.dart';
import '../domain/pillar.dart';
import '../domain/streak_calculator.dart';
import '../domain/xp_engine.dart';
import 'db/database.dart';

class CompletionResult {
  const CompletionResult({
    required this.habit,
    required this.xp,
    required this.drop,
    required this.streak,
    required this.pillarLevelBefore,
    required this.pillarLevelAfter,
  });

  final Habit habit;
  final int xp;
  final Drop drop;
  final StreakInfo streak;
  final int pillarLevelBefore;
  final int pillarLevelAfter;

  int get totalXp => xp + drop.bonusXp;
  bool get leveledUp => pillarLevelAfter > pillarLevelBefore;
}

class HabitRepository {
  HabitRepository(this._db);

  final AppDatabase _db;

  Stream<List<Habit>> watchHabits() => (_db.select(
    _db.habits,
  )..orderBy([(h) => OrderingTerm.asc(h.id)])).watch();

  Stream<List<Completion>> watchCompletions() =>
      _db.select(_db.completions).watch();

  Future<List<Habit>> getHabits() =>
      (_db.select(_db.habits)..orderBy([(h) => OrderingTerm.asc(h.id)])).get();

  Future<List<Completion>> getCompletions() =>
      _db.select(_db.completions).get();

  Future<Habit> createHabit({
    required String name,
    required Pillar pillar,
    required Frequency frequency,
    int? reminderMinutes,
    DateTime? now,
  }) => _db
      .into(_db.habits)
      .insertReturning(
        HabitsCompanion.insert(
          name: name.trim(),
          pillar: pillar,
          frequencyType: frequency.type,
          weekdaysMask: Value(frequency.weekdaysMask),
          timesPerWeek: Value(frequency.timesPerWeek),
          reminderMinutes: Value(reminderMinutes),
          createdAt: now ?? DateTime.now(),
        ),
      );

  Future<Habit> updateHabit(
    int id, {
    required String name,
    required Pillar pillar,
    required Frequency frequency,
    required int? reminderMinutes,
  }) async {
    final rows = await (_db.update(_db.habits)..where((h) => h.id.equals(id)))
        .writeReturning(
          HabitsCompanion(
            name: Value(name.trim()),
            pillar: Value(pillar),
            frequencyType: Value(frequency.type),
            weekdaysMask: Value(frequency.weekdaysMask),
            timesPerWeek: Value(frequency.timesPerWeek),
            reminderMinutes: Value(reminderMinutes),
          ),
        );
    return rows.single;
  }

  /// Mengarsipkan kebiasaan: hilang dari daftar, XP-nya tetap dihitung.
  Future<void> archiveHabit(int id, {DateTime? now}) =>
      (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
        HabitsCompanion(archivedAt: Value(now ?? DateTime.now())),
      );

  /// Menghapus kebiasaan beserta seluruh riwayat dan XP-nya.
  Future<void> deleteHabit(int id) =>
      (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();

  /// Menandai kebiasaan selesai pada [day]. Mengembalikan null bila kebiasaan
  /// tidak ada atau sudah diselesaikan pada hari itu.
  Future<CompletionResult?> completeHabit(
    int habitId, {
    required DateTime day,
    Random? random,
  }) => _db.transaction(() async {
    final allHabits = await getHabits();
    final habit = allHabits.where((h) => h.id == habitId).firstOrNull;
    if (habit == null) return null;

    final key = dayKey(day);
    final all = await getCompletions();
    final doneDays = {
      for (final c in all)
        if (c.habitId == habitId) c.day,
    };
    if (!doneDays.add(key)) return null;

    final streak = calculateStreak(
      doneDays: doneDays,
      frequency: habit.frequency,
      startDay: habit.createdAt.toLocal(),
      today: day,
    );
    final xp = xpForCompletion(streak.current);
    final drop = rollDrop(random ?? Random());

    final pillarHabitIds = {
      for (final h in allHabits)
        if (h.pillar == habit.pillar) h.id,
    };
    final pillarXpBefore = all
        .where((c) => pillarHabitIds.contains(c.habitId))
        .fold(0, (sum, c) => sum + c.xp + c.bonusXp);

    await _db
        .into(_db.completions)
        .insert(
          CompletionsCompanion.insert(
            habitId: habitId,
            day: key,
            completedAt: DateTime.now(),
            xp: xp,
            bonusXp: Value(drop.bonusXp),
            dropType: Value(drop.type),
          ),
        );

    return CompletionResult(
      habit: habit,
      xp: xp,
      drop: drop,
      streak: streak,
      pillarLevelBefore: LevelInfo.fromXp(pillarXpBefore).level,
      pillarLevelAfter: LevelInfo.fromXp(pillarXpBefore + xp + drop.bonusXp)
          .level,
    );
  });

  Future<void> undoCompletion(int habitId, {required DateTime day}) =>
      (_db.delete(_db.completions)..where(
            (c) => c.habitId.equals(habitId) & c.day.equals(dayKey(day)),
          ))
          .go();
}
