import 'dart:math';

/// Nama enum disimpan di database — jangan diubah.
enum DropType { none, bonusXp, insight, badgeFragment }

/// Jumlah fragmen yang membentuk satu badge langka.
const fragmentsPerBadge = 4;

const dropChance = 0.12;

class Drop {
  const Drop(this.type, {this.bonusXp = 0, this.insight});

  static const none = Drop(DropType.none);

  final DropType type;
  final int bonusXp;
  final String? insight;

  bool get isDrop => type != DropType.none;
}

/// Critical Focus Drop: hadiah variabel yang sesekali muncul saat kebiasaan
/// diselesaikan. [random] di-inject agar hasilnya bisa diuji.
Drop rollDrop(Random random) {
  if (random.nextDouble() >= dropChance) return Drop.none;
  final kind = random.nextDouble();
  if (kind < 0.5) {
    return Drop(DropType.bonusXp, bonusXp: 5 + random.nextInt(21));
  }
  if (kind < 0.8) {
    return Drop(
      DropType.insight,
      insight: insights[random.nextInt(insights.length)],
    );
  }
  return const Drop(DropType.badgeFragment);
}

const insights = [
  'Konsistensi kecil mengalahkan intensitas sesekali.',
  'Kamu tidak perlu sempurna hari ini. Kamu hanya perlu hadir.',
  'Satu hari terlewat adalah kecelakaan. Dua hari adalah awal kebiasaan baru.',
  'Disiplin adalah bentuk menghargai dirimu di masa depan.',
  'Fokus bukan soal melakukan lebih banyak, tapi memilih lebih sedikit.',
  'Yang kamu ulangi setiap hari perlahan menjadi siapa dirimu.',
  'Mulai dari versi yang terlalu mudah untuk gagal.',
  'Momentum dibangun diam-diam, lalu terasa sekaligus.',
];
