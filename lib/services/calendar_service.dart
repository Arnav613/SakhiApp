import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class CalendarService {
  static final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  // ── Request permission ────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  // ── Check permission ──────────────────────────────────────────────────────
  static Future<bool> hasPermission() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  // ── Fetch today's events from all calendars ───────────────────────────────
  static Future<List<Task>> getTodaysTasks() async {
    try {
      // Make sure we have permission
      final permitted = await hasPermission();
      if (!permitted) {
        final granted = await requestPermission();
        if (!granted) return _mockTasks(); // fall back to mock if denied
      }

      // Get all calendars on device
      final calendarsResult = await _plugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return _mockTasks();
      }

      final calendars = calendarsResult.data!;

      // Date range — today only
      final now   = DateTime.now();
      final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final end   = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final List<Task> tasks = [];

      // Fetch events from every calendar
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

          // Skip all-day events (they usually aren't tasks)
          if (event.allDay == true) continue;

          tasks.add(Task(
            id:    event.eventId ?? UniqueKey().toString(),
            title: event.title!.trim(),
            time:  event.start!,
          ));
        }
      }

      // Sort by time
      tasks.sort((a, b) => a.time.compareTo(b.time));

      // Return mock data if calendar is empty (common in emulators)
      if (tasks.isEmpty) return _mockTasks();

      return tasks;
    } catch (e) {
      debugPrint('CalendarService error: $e');
      return _mockTasks();
    }
  }

  // ── Fetch upcoming events (next 7 days) ───────────────────────────────────
  static Future<List<Task>> getUpcomingTasks() async {
    try {
      final permitted = await hasPermission();
      if (!permitted) {
        final granted = await requestPermission();
        if (!granted) return [];
      }

      final calendarsResult = await _plugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) return [];

      final calendars = calendarsResult.data!;
      final now   = DateTime.now();
      final start = now;
      final end   = now.add(const Duration(days: 7));

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
            id:    event.eventId ?? UniqueKey().toString(),
            title: event.title!.trim(),
            time:  event.start!,
          ));
        }
      }

      tasks.sort((a, b) => a.time.compareTo(b.time));
      return tasks;
    } catch (e) {
      debugPrint('CalendarService error: $e');
      return [];
    }
  }

  // ── Mock tasks for emulator / denied permission ───────────────────────────
  static List<Task> _mockTasks() {
    final now = DateTime.now();
    return [
      Task(id: '1', title: 'Team standup',      time: now.copyWith(hour: 9,  minute: 30)),
      Task(id: '2', title: 'Quarterly review',  time: now.copyWith(hour: 11, minute: 0)),
      Task(id: '3', title: 'Lunch with Priya',  time: now.copyWith(hour: 13, minute: 0)),
      Task(id: '4', title: 'Design review',     time: now.copyWith(hour: 15, minute: 30)),
      Task(id: '5', title: 'Reply to emails',   time: now.copyWith(hour: 17, minute: 0)),
    ];
  }
}