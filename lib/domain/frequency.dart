import '../core/day.dart';

/// Nama enum disimpan di database — jangan diubah.
enum FrequencyType { daily, weekdays, timesPerWeek }

class Frequency {
  const Frequency.daily()
    : type = FrequencyType.daily,
      weekdaysMask = allDaysMask,
      timesPerWeek = 7;

  /// [weekdaysMask]: bit 0 = Senin … bit 6 = Minggu.
  const Frequency.weekdays(this.weekdaysMask)
    : type = FrequencyType.weekdays,
      timesPerWeek = 0;

  const Frequency.timesPerWeek(this.timesPerWeek)
    : type = FrequencyType.timesPerWeek,
      weekdaysMask = allDaysMask;

  const Frequency.raw({
    required this.type,
    required this.weekdaysMask,
    required this.timesPerWeek,
  });

  static const allDaysMask = 0x7F;

  final FrequencyType type;
  final int weekdaysMask;
  final int timesPerWeek;

  /// Streak dihitung per minggu untuk kebiasaan "N× seminggu".
  bool get isWeekly => type == FrequencyType.timesPerWeek;

  bool includesWeekday(int weekday) => weekdaysMask & (1 << (weekday - 1)) != 0;

  /// Apakah kebiasaan dijadwalkan pada [day]. Kebiasaan mingguan boleh
  /// dikerjakan di hari apa pun.
  bool isScheduledOn(DateTime day) => switch (type) {
    FrequencyType.daily || FrequencyType.timesPerWeek => true,
    FrequencyType.weekdays => includesWeekday(day.weekday),
  };

  String get label => switch (type) {
    FrequencyType.daily => 'Setiap hari',
    FrequencyType.timesPerWeek => '$timesPerWeek× seminggu',
    FrequencyType.weekdays => [
      for (var i = 0; i < 7; i++)
        if (weekdaysMask & (1 << i) != 0) dayShortNames[i],
    ].join(' · '),
  };
}
