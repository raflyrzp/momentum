import 'dart:math' as math;

/// 66-Day Habit Mastery (Lally et al.): fase ditentukan oleh jumlah hari
/// kebiasaan diselesaikan, bukan oleh streak, sehingga tidak reset saat
/// satu hari terlewat.
const masteryTargetDays = 66;

enum MasteryPhase {
  fragile('Fragile', 'Kebiasaan masih rapuh. Jaga ritmenya.', 1, 21),
  building('Building', 'Fondasi mulai terbentuk.', 22, 65),
  forged('Forged', 'Kebiasaan sudah menjadi otomatis.', 66, null);

  const MasteryPhase(this.label, this.description, this.fromDay, this.toDay);

  final String label;
  final String description;
  final int fromDay;
  final int? toDay;
}

class Mastery {
  const Mastery(this.daysDone);

  final int daysDone;

  MasteryPhase get phase => daysDone >= MasteryPhase.forged.fromDay
      ? MasteryPhase.forged
      : daysDone >= MasteryPhase.building.fromDay
      ? MasteryPhase.building
      : MasteryPhase.fragile;

  double get progress => math.min(1, daysDone / masteryTargetDays);

  int get daysRemaining => math.max(0, masteryTargetDays - daysDone);
}
