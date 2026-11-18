import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/db/database.dart';
import '../domain/frequency.dart';

/// Pengingat lokal per kebiasaan. Semua kegagalan platform ditelan dan dicatat
/// supaya pengingat tidak pernah menghalangi alur utama aplikasi.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'habit_reminders',
      'Pengingat kebiasaan',
      channelDescription: 'Pengingat harian untuk kebiasaan Anda',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService.init gagal: $e');
    }
  }

  /// Meminta izin notifikasi; dipanggil saat pengguna pertama kali
  /// mengaktifkan pengingat.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    } catch (e) {
      debugPrint('requestPermission gagal: $e');
      return false;
    }
  }

  // Setiap kebiasaan memakai 8 id: slot 0 untuk pengingat harian, slot 1–7
  // untuk pengingat per hari (Senin–Minggu).
  int _id(int habitId, int slot) => habitId * 8 + slot;

  Future<void> cancelHabit(int habitId) async {
    if (!_ready) return;
    try {
      for (var slot = 0; slot < 8; slot++) {
        await _plugin.cancel(id: _id(habitId, slot));
      }
    } catch (e) {
      debugPrint('cancelHabit gagal: $e');
    }
  }

  /// Menjadwalkan ulang pengingat [habit] sesuai jam dan frekuensinya.
  Future<void> syncHabit(Habit habit) async {
    if (!_ready) return;
    await cancelHabit(habit.id);
    final minutes = habit.reminderMinutes;
    if (minutes == null || habit.archivedAt != null) return;

    try {
      final body = 'Tahan untuk menyelesaikan dan jaga momentummu.';
      if (habit.frequencyType == FrequencyType.weekdays) {
        for (var weekday = 1; weekday <= 7; weekday++) {
          if (!habit.frequency.includesWeekday(weekday)) continue;
          await _plugin.zonedSchedule(
            id: _id(habit.id, weekday),
            title: habit.name,
            body: body,
            scheduledDate: _next(minutes, weekday: weekday),
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        await _plugin.zonedSchedule(
          id: _id(habit.id, 0),
          title: habit.name,
          body: body,
          scheduledDate: _next(minutes),
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (e) {
      debugPrint('syncHabit gagal: $e');
    }
  }

  Future<void> showTest() async {
    if (!_ready) return;
    await requestPermission();
    await _plugin.show(
      id: 0,
      title: 'Momentum',
      body: 'Notifikasi uji: pengingat berfungsi.',
      notificationDetails: _details,
    );
  }

  tz.TZDateTime _next(int minutes, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutes ~/ 60,
      minutes % 60,
    );
    while (!at.isAfter(now) || (weekday != null && at.weekday != weekday)) {
      at = tz.TZDateTime(
        tz.local,
        at.year,
        at.month,
        at.day + 1,
        at.hour,
        at.minute,
      );
    }
    return at;
  }
}
