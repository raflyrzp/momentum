import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/day.dart';
import '../domain/frequency.dart';
import '../domain/pillar.dart';
import '../services/notification_service.dart';
import 'dashboard.dart';
import 'db/database.dart';
import 'habit_repository.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}

@Riverpod(keepAlive: true)
HabitRepository habitRepository(Ref ref) =>
    HabitRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
NotificationService notificationService(Ref ref) => NotificationService();

/// Pergeseran "hari ini" dalam hari. Selalu 0 di rilis; menu debug memakainya
/// untuk mensimulasikan hari berikutnya (menguji streak dan shield).
@Riverpod(keepAlive: true)
class DayOffset extends _$DayOffset {
  @override
  int build() => 0;

  void shift(int days) => state += days;
  void reset() => state = 0;
}

@riverpod
DateTime today(Ref ref) =>
    addDays(dateOnly(DateTime.now()), ref.watch(dayOffsetProvider));

// Ditulis manual: `Habit` dan `Completion` adalah tipe hasil generate drift,
// yang belum bisa di-resolve oleh riverpod_generator dalam build yang sama.
final allHabitsProvider = StreamProvider.autoDispose<List<Habit>>(
  (ref) => ref.watch(habitRepositoryProvider).watchHabits(),
);

final allCompletionsProvider = StreamProvider.autoDispose<List<Completion>>(
  (ref) => ref.watch(habitRepositoryProvider).watchCompletions(),
);

@riverpod
Future<Dashboard> dashboard(Ref ref) async {
  final habits = await ref.watch(allHabitsProvider.future);
  final completions = await ref.watch(allCompletionsProvider.future);
  return buildDashboard(
    habits: habits,
    completions: completions,
    today: ref.watch(todayProvider),
  );
}

@Riverpod(keepAlive: true)
HabitActions habitActions(Ref ref) => HabitActions(ref);

/// Aksi tulis yang dipakai UI; menjaga pengingat tetap sinkron dengan data.
class HabitActions {
  HabitActions(this._ref);

  final Ref _ref;

  HabitRepository get _repo => _ref.read(habitRepositoryProvider);
  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);

  Future<void> save({
    int? id,
    required String name,
    required Pillar pillar,
    required Frequency frequency,
    required int? reminderMinutes,
  }) async {
    final habit = id == null
        ? await _repo.createHabit(
            name: name,
            pillar: pillar,
            frequency: frequency,
            reminderMinutes: reminderMinutes,
          )
        : await _repo.updateHabit(
            id,
            name: name,
            pillar: pillar,
            frequency: frequency,
            reminderMinutes: reminderMinutes,
          );
    if (reminderMinutes != null) await _notifications.requestPermission();
    await _notifications.syncHabit(habit);
  }

  Future<void> archive(int id) async {
    await _repo.archiveHabit(id);
    await _notifications.cancelHabit(id);
  }

  Future<void> delete(int id) async {
    await _repo.deleteHabit(id);
    await _notifications.cancelHabit(id);
  }

  Future<CompletionResult?> complete(int habitId) =>
      _repo.completeHabit(habitId, day: _ref.read(todayProvider));

  Future<void> undo(int habitId) =>
      _repo.undoCompletion(habitId, day: _ref.read(todayProvider));
}
