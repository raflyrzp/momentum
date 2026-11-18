import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:momentum/domain/drop_roller.dart';
import 'package:momentum/domain/mastery.dart';
import 'package:momentum/domain/xp_engine.dart';

/// Random palsu dengan urutan nilai yang ditentukan.
class _FakeRandom implements Random {
  _FakeRandom({this.doubles = const [], this.ints = const []});

  final List<double> doubles;
  final List<int> ints;
  var _d = 0;
  var _i = 0;

  @override
  double nextDouble() => doubles[_d++];

  @override
  int nextInt(int max) => ints[_i++] % max;

  @override
  bool nextBool() => false;
}

void main() {
  group('XP', () {
    test('bonus streak +10% per 7 periode, maksimal +50%', () {
      expect(xpForCompletion(0), 10);
      expect(xpForCompletion(6), 10);
      expect(xpForCompletion(7), 11);
      expect(xpForCompletion(14), 12);
      expect(xpForCompletion(35), 15);
      expect(xpForCompletion(365), 15);
    });

    test('kurva level kuadratik', () {
      expect(LevelInfo.fromXp(0).level, 1);
      expect(LevelInfo.fromXp(99).level, 1);
      expect(LevelInfo.fromXp(100).level, 2);
      expect(LevelInfo.fromXp(299).level, 2);
      expect(LevelInfo.fromXp(300).level, 3);

      final info = LevelInfo.fromXp(150);
      expect(info.xpIntoLevel, 50);
      expect(info.xpForLevel, 200);
      expect(info.progress, 0.25);
    });
  });

  group('Critical Focus Drop', () {
    test('tidak ada drop di atas ambang peluang', () {
      expect(rollDrop(_FakeRandom(doubles: [dropChance])).isDrop, isFalse);
      expect(rollDrop(_FakeRandom(doubles: [0.99])).type, DropType.none);
    });

    test('bonus XP berada di rentang 5–25', () {
      final low = rollDrop(_FakeRandom(doubles: [0.01, 0.1], ints: [0]));
      expect(low.type, DropType.bonusXp);
      expect(low.bonusXp, 5);

      final high = rollDrop(_FakeRandom(doubles: [0.01, 0.1], ints: [20]));
      expect(high.bonusXp, 25);
    });

    test('wawasan dan fragmen badge', () {
      final insight = rollDrop(_FakeRandom(doubles: [0.01, 0.6], ints: [2]));
      expect(insight.type, DropType.insight);
      expect(insight.insight, insights[2]);
      expect(insight.bonusXp, 0);

      final fragment = rollDrop(_FakeRandom(doubles: [0.01, 0.9]));
      expect(fragment.type, DropType.badgeFragment);
    });

    test('peluang drop mendekati 12% pada banyak percobaan', () {
      final random = Random(42);
      var drops = 0;
      for (var i = 0; i < 20000; i++) {
        if (rollDrop(random).isDrop) drops++;
      }
      expect(drops / 20000, closeTo(dropChance, 0.01));
    });
  });

  group('66-Day Mastery', () {
    test('batas fase', () {
      expect(const Mastery(0).phase, MasteryPhase.fragile);
      expect(const Mastery(21).phase, MasteryPhase.fragile);
      expect(const Mastery(22).phase, MasteryPhase.building);
      expect(const Mastery(65).phase, MasteryPhase.building);
      expect(const Mastery(66).phase, MasteryPhase.forged);
    });

    test('progres dibatasi sampai 100%', () {
      expect(const Mastery(33).progress, 0.5);
      expect(const Mastery(200).progress, 1);
      expect(const Mastery(60).daysRemaining, 6);
      expect(const Mastery(200).daysRemaining, 0);
    });
  });
}
