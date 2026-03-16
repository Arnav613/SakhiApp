import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import 'claude_service.dart' hide CycleState;
import '../models/models.dart';
import '../providers/providers.dart';

// Simplified background service — no workmanager needed
// Morning notification is scheduled via flutter_local_notifications
// and refreshed each time the app opens

class BackgroundService {
  static Future<void> init() async {
    // Refresh morning notification message when app opens
    await refreshMorningNotification();
  }

  // Public — used by test button in settings
  static Future<String> generateMorningMessage({
    required String userName,
    required CycleState cycle,
    required String lastJournal,
  }) async {
    try {
      return await ClaudeService.getMorningCheckIn(
        cycle:           cycle,
        tasks:           [],
        userName:        userName.isNotEmpty ? userName : 'there',
        lastJournalNote: lastJournal,
      );
    } catch (e) {
      return "Good morning${userName.isNotEmpty ? ', $userName' : ''}! "
          "You're on day ${cycle.dayOfCycle} — ${cycle.phase.label} phase. "
          "${cycle.phase.tagline}. Open Sakhi to see today's plan. 🌸";
    }
  }

  // Called on app open — reschedules morning notification with fresh Claude message
  static Future<void> refreshMorningNotification() async {
    try {
      final settings = StorageService.getNotificationSettings();
      final enabled  = settings['morningEnabled'] as bool? ?? true;
      if (!enabled) return;

      final hour   = settings['morningHour']   as int? ?? 7;
      final minute = settings['morningMinute'] as int? ?? 30;

      final savedCycle  = StorageService.getCycleData();
      final userName    = StorageService.getUserName();
      final lastJournal = StorageService.getLastJournalNote();

      final dayOfCycle  = savedCycle['dayOfCycle']  as int;
      final cycleLength = savedCycle['cycleLength'] as int;
      final phase       = _phaseFromString(savedCycle['phase'] as String);

      final cycle = CycleState(
        dayOfCycle:  dayOfCycle,
        phase:       phase,
        cycleLength: cycleLength,
      );

      // Get Claude message
      String message;
      try {
        message = await ClaudeService.getMorningCheckIn(
          cycle:           cycle,
          tasks:           [],
          userName:        userName.isNotEmpty ? userName : 'there',
          lastJournalNote: lastJournal,
        );
      } catch (e) {
        // Fallback if no internet
        message = "Good morning${userName.isNotEmpty ? ', $userName' : ''}! "
            "You're on day $dayOfCycle — ${phase.label} phase. "
            "${phase.tagline}. Open Sakhi to see today's plan. 🌸";
      }

      // Save message for home screen to display
      await StorageService.saveLastCheckInMessage(message);

      // Reschedule notification with fresh message
      await NotificationService.scheduleMorningCheckIn(
        hour:    hour,
        minute:  minute,
        message: message,
      );

      debugPrint('Morning notification refreshed');
    } catch (e) {
      debugPrint('Background service error: $e');
    }
  }

  // Schedule morning task — just uses local notifications
  static Future<void> scheduleMorningTask({
    required int hour,
    required int minute,
  }) async {
    await refreshMorningNotification();
  }

  static Future<void> cancelMorningTask() async {
    await NotificationService.cancel(1);
  }
}

CyclePhase _phaseFromString(String s) {
  switch (s) {
    case 'menstrual':  return CyclePhase.menstrual;
    case 'follicular': return CyclePhase.follicular;
    case 'ovulatory':  return CyclePhase.ovulatory;
    case 'luteal':     return CyclePhase.luteal;
    default:           return CyclePhase.ovulatory;
  }
}