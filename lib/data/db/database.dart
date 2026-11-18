import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/drop_roller.dart';
import '../../domain/frequency.dart';
import '../../domain/pillar.dart';

part 'database.g.dart';

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get pillar => textEnum<Pillar>()();
  TextColumn get frequencyType => textEnum<FrequencyType>()();

  /// Bit 0 = Senin … bit 6 = Minggu. Dipakai bila frequencyType = weekdays.
  IntColumn get weekdaysMask =>
      integer().withDefault(const Constant(Frequency.allDaysMask))();

  /// Dipakai bila frequencyType = timesPerWeek.
  IntColumn get timesPerWeek => integer().withDefault(const Constant(3))();

  /// Jam pengingat dalam menit sejak tengah malam; null = tanpa pengingat.
  IntColumn get reminderMinutes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();
}

class Completions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get habitId =>
      integer().references(Habits, #id, onDelete: KeyAction.cascade)();

  /// Hari lokal dalam format yyyymmdd.
  IntColumn get day => integer()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get xp => integer()();
  IntColumn get bonusXp => integer().withDefault(const Constant(0))();
  TextColumn get dropType =>
      textEnum<DropType>().withDefault(Constant(DropType.none.name))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitId, day},
  ];
}

@DriftDatabase(tables: [Habits, Completions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // Dibagi antar-isolate supaya callback latar home widget dan aplikasi
  // memakai koneksi yang sama (stream ikut ter-update).
  static QueryExecutor _open() => driftDatabase(
    name: 'momentum',
    native: const DriftNativeOptions(shareAcrossIsolates: true),
  );
}

extension HabitFrequency on Habit {
  Frequency get frequency => Frequency.raw(
    type: frequencyType,
    weekdaysMask: weekdaysMask,
    timesPerWeek: timesPerWeek,
  );
}
