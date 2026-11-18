/// Utilitas "hari lokal". Sebuah hari direpresentasikan sebagai `DateTime` UTC
/// tepat tengah malam supaya aritmetika tanggal tidak terpengaruh DST, dan
/// disimpan di database sebagai kunci `yyyymmdd`.
library;

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

DateTime dayFromKey(int key) =>
    DateTime.utc(key ~/ 10000, (key ~/ 100) % 100, key % 100);

DateTime addDays(DateTime day, int n) =>
    DateTime.utc(day.year, day.month, day.day + n);

/// Senin pada minggu yang memuat [day].
DateTime weekStart(DateTime day) => addDays(dateOnly(day), 1 - day.weekday);

const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const dayShortNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const monthShortNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Contoh: "Sabtu, 14 November".
String formatLongDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]}';
