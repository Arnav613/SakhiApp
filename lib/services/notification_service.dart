import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Notification IDs ──────────────────────────────────────────────────────
  static const int _morningCheckInId  = 1;
  static const int _eveningJournalId  = 2;
  static const int _preTaskBaseId     = 100; // 100–199 reserved for pre-task

  // ── Initialise ────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission:  true,
      requestBadgePermission:  true,
      requestSoundPermission:  true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'sakhi_channel',
      'Sakhi',
      description: 'Sakhi daily check-ins and reminders',
      importance:  Importance.high,
      playSound:   true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission (Android 13+)
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  // ── Notification details ──────────────────────────────────────────────────
  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      'sakhi_channel',
      'Sakhi',
      channelDescription: 'Sakhi daily check-ins and reminders',
      importance:         Importance.high,
      priority:           Priority.high,
      icon:               '@mipmap/ic_launcher',
      color:              Color(0xFFC4527A),
      playSound:          true,
      enableVibration:    true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ── Schedule morning check-in (daily at set time) ─────────────────────────
  static Future<void> scheduleMorningCheckIn({
    required int hour,
    required int minute,
    required String message,
  }) async {
    await _plugin.cancel(_morningCheckInId);

    final now      = tz.TZDateTime.now(tz.local);
    var   scheduled = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _morningCheckInId,
      'Good morning 🌸',
      message,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );

    debugPrint('Morning check-in scheduled for ${hour.toString().padLeft(2,"0")}:${minute.toString().padLeft(2,"0")} daily');
  }

  // ── Schedule evening journal reminder ─────────────────────────────────────
  static Future<void> scheduleEveningJournal({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(_eveningJournalId);

    final now       = tz.TZDateTime.now(tz.local);
    var   scheduled  = tz.TZDateTime(
      tz.local,
      now.year, now.month, now.day,
      hour, minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _eveningJournalId,
      'Time to journal 📖',
      'How did today go? Rate your tasks and jot down your thoughts — Sakhi will read it tonight.',
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('Evening journal scheduled for ${hour.toString().padLeft(2,"0")}:${minute.toString().padLeft(2,"0")} daily');
  }

  // ── Schedule pre-task notification ────────────────────────────────────────
  static Future<void> schedulePreTaskNotification({
    required int index,
    required String taskTitle,
    required String phaseMessage,
    required DateTime taskTime,
  }) async {
    // Notify 30 minutes before the task
    final notifyAt = taskTime.subtract(const Duration(minutes: 30));
    if (notifyAt.isBefore(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(notifyAt, tz.local);

    await _plugin.zonedSchedule(
      _preTaskBaseId + index,
      '${taskTitle} in 30 minutes',
      phaseMessage,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('Pre-task notification scheduled for $taskTitle at $notifyAt');
  }

  // ── Send immediate notification ───────────────────────────────────────────
  static Future<void> showNow({
    required String title,
    required String body,
    int id = 999,
  }) async {
    await _plugin.show(id, title, body, _details);
  }

  // ── Cancel specific notification ──────────────────────────────────────────
  static Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  // ── Cancel all notifications ──────────────────────────────────────────────
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Get scheduled notifications (for settings display) ───────────────────
  static Future<List<PendingNotificationRequest>> getPending() async {
    return await _plugin.pendingNotificationRequests();
  }
}