import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  // ── Request permission explicitly ─────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  // ── Check permission ──────────────────────────────────────────────────────
  static Future<bool> hasPermission() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  // ── Get today's tasks — always requests permission if not granted ─────────
  static Future<List<Task>> getTodaysTasks() async {
    try {
      // Always request — if already granted it returns true silently
      // If not granted it shows the system permission popup
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('Calendar permission denied — using mock data');
        return _mockTasks();
      }

      final calendarsResult = await _plugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        debugPrint('Could not retrieve calendars');
        return _mockTasks();
      }

      final calendars = calendarsResult.data!;
      if (calendars.isEmpty) {
        debugPrint('No calendars found on device');
        return _mockTasks();
      }

      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end   = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final List<Task> tasks = [];

      for (final calendar in calendars) {
        if (calendar.id == null) continue;

        final eventsResult = await _plugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(startDate: start, endDate: end),
        );

        if (!eventsResult.isSuccess || eventsResult.data == null) continue;

        for (final event in eventsResult.data!) {
          if (event.title == null || event.title!.trim().isEmpty) continue;
          if (event.start == null) continue;
          if (event.allDay == true) continue;

          tasks.add(Task(
            id:    event.eventId ?? '${event.title}_${event.start}',
            title: event.title!.trim(),
            time:  event.start!,
          ));
        }
      }

      tasks.sort((a, b) => a.time.compareTo(b.time));

      if (tasks.isEmpty) {
        debugPrint('No events today — using mock data');
        return _mockTasks();
      }

      debugPrint('Loaded ${tasks.length} events from calendar');
      return tasks;
    } catch (e) {
      debugPrint('CalendarService error: $e');
      return _mockTasks();
    }
  }

  // ── Mock tasks fallback ───────────────────────────────────────────────────
  static List<Task> _mockTasks() {
    final now = DateTime.now();
    return [
      Task(id: '1', title: 'Team standup',     time: now.copyWith(hour: 9,  minute: 30)),
      Task(id: '2', title: 'Quarterly review', time: now.copyWith(hour: 11, minute: 0)),
      Task(id: '3', title: 'Lunch break',      time: now.copyWith(hour: 13, minute: 0)),
      Task(id: '4', title: 'Design review',    time: now.copyWith(hour: 15, minute: 30)),
      Task(id: '5', title: 'Wrap up',          time: now.copyWith(hour: 17, minute: 0)),
    ];
  }
}