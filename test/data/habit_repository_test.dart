import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/core/day.dart';
import 'package:momentum/data/dashboard.dart';
import 'package:momentum/data/db/database.dart';
import 'package:momentum/data/habit_repository.dart';
import 'package:momentum/domain/drop_roller.dart';
import 'package:momentum/domain/frequency.dart';
import 'package:momentum/domain/pillar.dart';

/// Tidak pernah menghasilkan drop.
class _NoDrop implements Random {
  @override
  double nextDouble() => 0.99;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

/// Selalu menghasilkan bonus XP +25.
class _BonusDrop implements Random {
  var _calls = 0;
  @override
  double nextDouble() => _calls++ == 0 ? 0.0 : 0.1;
  @override
  int nextInt(int max) => 20;
  @override
  bool nextBool() => false;
}

void main() {
  late AppDatabase db;
  late HabitRepository repo;
  final start = DateTime.utc(2026, 1, 5); // Senin
  final createdAt = DateTime(2026, 1, 5, 8);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = HabitRepository(db);
  });
  tearDown(() => db.close());

  Future<Habit> newHabit({
    String name = 'Membaca',
    Pillar pillar = Pillar.intellect,
    Frequency frequency = const Frequency.daily(),
  }) => repo.createHabit(
    name: name,
    pillar: pillar,
    frequency: frequency,
    now: createdAt,
  );

  Future<Dashboard> dashboard(DateTime today) async => buildDashboard(
    habits: await repo.getHabits(),
    completions: await repo.getCompletions(),
    today: today,
  );

  test('menyelesaikan kebiasaan memberi XP ke pilarnya', () async {
    final habit = await newHabit();
    final result = await repo.completeHabit(
      habit.id,
      day: start,
      random: _NoDrop(),
    );

    expect(result, isNotNull);
    expect(result!.xp, 10);
    expect(result.streak.current, 1);
    expect(result.drop.isDrop, isFalse);

    final d = await dashboard(start);
    expect(d.pillarXp[Pillar.intellect], 10);
    expect(d.pillarXp[Pillar.vitality], 0);
    expect(d.todayHabits.single.doneToday, isTrue);
    expect(d.heatmap[dayKey(start)], 1);
  });

  test('tidak bisa diselesaikan dua kali di hari yang sama', () async {
    final habit = await newHabit();
    await repo.completeHabit(habit.id, day: start, random: _NoDrop());
    final again = await repo.completeHabit(
      habit.id,
      day: start,
      random: _NoDrop(),
    );

    expect(again, isNull);
    expect(await repo.getCompletions(), hasLength(1));
  });

  test('kebiasaan yang tidak ada mengembalikan null', () async {
    expect(await repo.completeHabit(999, day: start), isNull);
  });

  test('urungkan menghapus penyelesaian dan XP-nya', () async {
    final habit = await newHabit();
    await repo.completeHabit(habit.id, day: start, random: _NoDrop());
    await repo.undoCompletion(habit.id, day: start);

    final d = await dashboard(start);
    expect(d.totalXp, 0);
    expect(d.todayHabits.single.doneToday, isFalse);
  });

  test('bonus drop disimpan dan dihitung sebagai XP', () async {
    final habit = await newHabit();
    final result = await repo.completeHabit(
      habit.id,
      day: start,
      random: _BonusDrop(),
    );

    expect(result!.drop.type, DropType.bonusXp);
    expect(result.totalXp, 35);
    expect((await dashboard(start)).pillarXp[Pillar.intellect], 35);
  });

  test('XP naik dengan streak dan melaporkan kenaikan level', () async {
    final habit = await newHabit();
    CompletionResult? last;
    // 10 XP × 6 hari + 11 XP × 3 hari = 93, hari ke-10 (+11) menembus 100.
    for (var i = 0; i < 10; i++) {
      last = await repo.completeHabit(
        habit.id,
        day: addDays(start, i),
        random: _NoDrop(),
      );
      if (i < 9) expect(last!.leveledUp, isFalse, reason: 'hari ${i + 1}');
    }

    expect(last!.xp, 11);
    expect(last.leveledUp, isTrue);
    expect(last.pillarLevelAfter, 2);
    expect(
      (await dashboard(addDays(start, 9))).pillarLevel(Pillar.intellect).level,
      2,
    );
  });

  test('arsip menyembunyikan kebiasaan tetapi mempertahankan XP', () async {
    final habit = await newHabit();
    await repo.completeHabit(habit.id, day: start, random: _NoDrop());
    await repo.archiveHabit(habit.id);

    final d = await dashboard(start);
    expect(d.habits, isEmpty);
    expect(d.totalXp, 10);
  });

  test('hapus permanen ikut menghapus riwayat', () async {
    final habit = await newHabit();
    await repo.completeHabit(habit.id, day: start, random: _NoDrop());
    await repo.deleteHabit(habit.id);

    expect(await repo.getCompletions(), isEmpty);
    expect((await dashboard(start)).totalXp, 0);
  });

  test('ubah kebiasaan menyimpan frekuensi dan pengingat', () async {
    final habit = await newHabit();
    final updated = await repo.updateHabit(
      habit.id,
      name: '  Lari pagi ',
      pillar: Pillar.vitality,
      frequency: const Frequency.timesPerWeek(3),
      reminderMinutes: 6 * 60 + 30,
    );

    expect(updated.name, 'Lari pagi');
    expect(updated.pillar, Pillar.vitality);
    expect(updated.frequency.isWeekly, isTrue);
    expect(updated.frequency.timesPerWeek, 3);
    expect(updated.reminderMinutes, 390);
  });

  test('dashboard: jadwal hari tertentu dan progres mingguan', () async {
    final weekdays = await newHabit(
      name: 'Gym',
      pillar: Pillar.vitality,
      frequency: const Frequency.weekdays(1 | 4 | 16), // Sen, Rab, Jum
    );
    final weekly = await newHabit(
      name: 'Jurnal',
      pillar: Pillar.mindfulness,
      frequency: const Frequency.timesPerWeek(2),
    );
    await repo.completeHabit(weekly.id, day: start, random: _NoDrop());

    final tuesday = await dashboard(addDays(start, 1));
    expect(tuesday.todayHabits.map((h) => h.habit.id), [weekly.id]);
    expect(tuesday.habitById(weekly.id)!.doneThisWeek, 1);
    expect(tuesday.habitById(weekly.id)!.doneToday, isFalse);

    final wednesday = await dashboard(addDays(start, 2));
    expect(
      wednesday.todayHabits.map((h) => h.habit.id),
      containsAll([weekdays.id, weekly.id]),
    );
  });
}
