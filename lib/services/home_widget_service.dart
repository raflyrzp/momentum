import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/day.dart';
import '../data/dashboard.dart';
import '../data/db/database.dart';
import '../data/habit_repository.dart';

const _androidWidget = 'dev.momentum.momentum.MomentumWidgetReceiver';

/// Kunci data yang dibaca oleh widget native (lihat MomentumWidget.kt).
const widgetKeyHabits = 'today_json';
const widgetKeyDay = 'today_day';

/// Mengirim daftar kebiasaan hari ini ke home-screen widget.
Future<void> pushHomeWidget(Dashboard dashboard) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final items = [
      for (final h in dashboard.todayHabits)
        {
          'id': h.habit.id,
          'name': h.habit.name,
          'pillar': h.habit.pillar.name,
          'done': h.doneToday,
          'streak': h.streak.current,
        },
    ];
    await HomeWidget.saveWidgetData<String>(widgetKeyHabits, jsonEncode(items));
    await HomeWidget.saveWidgetData<String>(
      widgetKeyDay,
      dayKey(dashboard.today).toString(),
    );
    await HomeWidget.updateWidget(qualifiedAndroidName: _androidWidget);
  } catch (e) {
    debugPrint('pushHomeWidget gagal: $e');
  }
}

/// Meminta launcher memasang widget "Hari Ini" di home screen.
Future<void> requestPinHomeWidget() async {
  try {
    await HomeWidget.requestPinWidget(qualifiedAndroidName: _androidWidget);
  } catch (e) {
    debugPrint('requestPinHomeWidget gagal: $e');
  }
}

/// Dipanggil di isolate latar saat pengguna mencentang kebiasaan dari widget
/// (URI: `momentum://complete?id=<habitId>`), tanpa membuka aplikasi.
@pragma('vm:entry-point')
Future<void> homeWidgetInteractivityCallback(Uri? uri) async {
  if (uri == null || uri.host != 'complete') return;
  final id = int.tryParse(uri.queryParameters['id'] ?? '');
  if (id == null) return;

  final db = AppDatabase();
  try {
    final repo = HabitRepository(db);
    final today = dateOnly(DateTime.now());
    await repo.completeHabit(id, day: today);
    await pushHomeWidget(
      buildDashboard(
        habits: await repo.getHabits(),
        completions: await repo.getCompletions(),
        today: today,
      ),
    );
  } finally {
    await db.close();
  }
}
