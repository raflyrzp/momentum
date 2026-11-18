import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/core/day.dart';
import 'package:momentum/domain/frequency.dart';
import 'package:momentum/domain/streak_calculator.dart';

void main() {
  // Senin, 5 Januari 2026.
  final start = DateTime.utc(2026, 1, 5);
  DateTime day(int n) => addDays(start, n);
  Set<int> days(Iterable<int> offsets) => {
    for (final n in offsets) dayKey(day(n)),
  };
  Iterable<int> range(int from, int to) =>
      Iterable.generate(to - from + 1, (i) => from + i);

  StreakInfo daily(Iterable<int> done, {required int today}) => calculateStreak(
    doneDays: days(done),
    frequency: const Frequency.daily(),
    startDay: start,
    today: day(today),
  );

  group('kebiasaan harian', () {
    test('tanpa riwayat: streak 0 dan shield siap', () {
      final s = daily([], today: 0);
      expect(s.current, 0);
      expect(s.shieldReady, isTrue);
      expect(s.shieldActive, isFalse);
    });

    test('hari berturut-turut termasuk hari ini', () {
      expect(daily(range(0, 4), today: 4).current, 5);
    });

    test('hari ini yang belum selesai tidak memutus streak', () {
      final s = daily(range(0, 3), today: 4);
      expect(s.current, 4);
      expect(s.shieldActive, isFalse);
    });

    test('satu hari terlewat dijembatani shield', () {
      final s = daily(range(0, 4), today: 6);
      expect(s.current, 5);
      expect(s.shieldActive, isTrue);
      expect(s.shieldReady, isFalse);
      expect(s.shieldCharge, 0);
    });

    test('menyelesaikan hari setelah shield melanjutkan streak', () {
      final s = daily([...range(0, 4), 6], today: 6);
      expect(s.current, 6);
      expect(s.shieldActive, isFalse);
      expect(s.shieldCharge, 1);
    });

    test(
      'never miss twice: dua hari terlewat berturut-turut memutus streak',
      () {
        final s = daily(range(0, 4), today: 7);
        expect(s.current, 0);
        expect(s.best, 5);
        expect(s.shieldActive, isFalse);
      },
    );

    test('terlewat lagi sebelum shield terisi ulang memutus streak', () {
      // Selesai 0–4, lewat 5 (shield), selesai 6–7, lewat 8.
      final s = daily([...range(0, 4), 6, 7], today: 9);
      expect(s.current, 0);
      expect(s.best, 7);
    });

    test('shield terisi ulang setelah 7 penyelesaian', () {
      // Selesai 0–4, lewat 5 (shield), selesai 6–12 (7×), lewat 13.
      final s = daily([...range(0, 4), ...range(6, 12)], today: 14);
      expect(s.current, 12);
      expect(s.shieldActive, isTrue);
    });

    test('tanpa streak, hari terlewat tidak menghabiskan shield', () {
      final s = daily([3], today: 3);
      expect(s.current, 1);
      expect(s.shieldReady, isTrue);
    });
  });

  group('hari tertentu', () {
    // Senin, Rabu, Jumat.
    const frequency = Frequency.weekdays(1 | 4 | 16);

    test('hari di luar jadwal tidak memutus streak', () {
      final s = calculateStreak(
        doneDays: days([0, 2, 4, 7]),
        frequency: frequency,
        startDay: start,
        today: day(8), // Selasa
      );
      expect(s.current, 4);
      expect(s.isWeekly, isFalse);
    });

    test('satu jadwal terlewat dijembatani, dua memutus', () {
      final bridged = calculateStreak(
        doneDays: days([0, 2]),
        frequency: frequency,
        startDay: start,
        today: day(7), // Jumat (4) terlewat, Senin berjalan
      );
      expect(bridged.current, 2);
      expect(bridged.shieldActive, isTrue);

      final broken = calculateStreak(
        doneDays: days([0, 2]),
        frequency: frequency,
        startDay: start,
        today: day(9), // Jumat (4) dan Senin (7) terlewat
      );
      expect(broken.current, 0);
    });
  });

  group('N× seminggu', () {
    const frequency = Frequency.timesPerWeek(3);

    StreakInfo weekly(Iterable<int> done, {required int today}) =>
        calculateStreak(
          doneDays: days(done),
          frequency: frequency,
          startDay: start,
          today: day(today),
        );

    test('streak dihitung per minggu yang memenuhi target', () {
      final s = weekly([0, 1, 2, 7, 9, 11, 14], today: 15);
      expect(s.isWeekly, isTrue);
      expect(s.unit, 'minggu');
      expect(s.current, 2); // minggu berjalan baru 1/3
    });

    test('minggu berjalan dihitung begitu target tercapai', () {
      expect(weekly([0, 1, 2, 7, 9, 11, 14, 15, 16], today: 16).current, 3);
    });

    test('satu minggu gagal dijembatani shield, dua minggu memutus', () {
      final bridged = weekly([0, 1, 2, 7, 8, 9, 14], today: 21);
      expect(bridged.current, 2);
      expect(bridged.shieldActive, isTrue);

      final broken = weekly([0, 1, 2, 7, 8, 9, 14], today: 28);
      expect(broken.current, 0);
      expect(broken.best, 2);
    });
  });
}
