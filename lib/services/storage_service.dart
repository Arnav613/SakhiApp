import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class StorageService {
  static const String _cycleBox    = 'cycle';
  static const String _journalBox  = 'journal';
  static const String _pointsBox   = 'points';
  static const String _settingsBox = 'settings';

  // ── Initialise Hive ───────────────────────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_cycleBox);
    await Hive.openBox(_journalBox);
    await Hive.openBox(_pointsBox);
    await Hive.openBox(_settingsBox);
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  static Future<void> saveUserName(String name) async {
    final box = Hive.box(_settingsBox);
    await box.put('userName', name);
  }

  static String getUserName() {
    final box = Hive.box(_settingsBox);
    return box.get('userName', defaultValue: '') as String;
  }

  static Future<void> saveOnboardingComplete(bool done) async {
    final box = Hive.box(_settingsBox);
    await box.put('onboardingComplete', done);
  }

  static bool getOnboardingComplete() {
    final box = Hive.box(_settingsBox);
    return box.get('onboardingComplete', defaultValue: false) as bool;
  }

  // ── Cycle data ────────────────────────────────────────────────────────────
  static Future<void> saveCycleData({
    required int dayOfCycle,
    required int cycleLength,
    required String phase,
    required String lastPeriodStart,
  }) async {
    final box = Hive.box(_cycleBox);
    await box.put('dayOfCycle',      dayOfCycle);
    await box.put('cycleLength',     cycleLength);
    await box.put('phase',           phase);
    await box.put('lastPeriodStart', lastPeriodStart);
  }

  static Map<String, dynamic> getCycleData() {
    final box = Hive.box(_cycleBox);
    return {
      'dayOfCycle':      box.get('dayOfCycle',      defaultValue: 14),
      'cycleLength':     box.get('cycleLength',     defaultValue: 28),
      'phase':           box.get('phase',           defaultValue: 'ovulatory'),
      'lastPeriodStart': box.get('lastPeriodStart', defaultValue: ''),
    };
  }

  // ── Journal entries ───────────────────────────────────────────────────────
  static Future<void> saveJournalEntry({
    required String date,
    required String phase,
    required String notes,
    required List<Map<String, dynamic>> taskRatings,
  }) async {
    final box     = Hive.box(_journalBox);
    final entries = _getJournalList(box);
    entries.insert(0, {
      'date':        date,
      'phase':       phase,
      'notes':       notes,
      'taskRatings': taskRatings,
    });
    // Keep last 90 entries
    final trimmed = entries.take(90).toList();
    await box.put('entries', trimmed);
  }

  static List<Map<String, dynamic>> getJournalEntries() {
    final box = Hive.box(_journalBox);
    return _getJournalList(box);
  }

  static String getLastJournalNote() {
    final entries = getJournalEntries();
    if (entries.isEmpty) return '';
    return entries.first['notes'] as String? ?? '';
  }

  static List<Map<String, dynamic>> _getJournalList(Box box) {
    final raw = box.get('entries');
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
        (raw as List).map((e) => Map<String, dynamic>.from(e as Map)));
  }

  // ── Resilience points ─────────────────────────────────────────────────────
  static Future<void> savePoints({
    required int totalPoints,
    required int journalStreak,
    required int tasksCompletedThisCycle,
    required List<int> weeklyPoints,
  }) async {
    final box = Hive.box(_pointsBox);
    await box.put('totalPoints',             totalPoints);
    await box.put('journalStreak',           journalStreak);
    await box.put('tasksCompletedThisCycle', tasksCompletedThisCycle);
    await box.put('weeklyPoints',            weeklyPoints);
  }

  static Map<String, dynamic> getPoints() {
    final box = Hive.box(_pointsBox);
    return {
      'totalPoints':             box.get('totalPoints',             defaultValue: 0),
      'journalStreak':           box.get('journalStreak',           defaultValue: 0),
      'tasksCompletedThisCycle': box.get('tasksCompletedThisCycle', defaultValue: 0),
      'weeklyPoints':            List<int>.from(
          box.get('weeklyPoints', defaultValue: [0,0,0,0,0,0,0]) as List),
    };
  }

  // ── Last morning check-in date ────────────────────────────────────────────
  static Future<void> saveLastCheckInDate(String date) async {
    final box = Hive.box(_settingsBox);
    await box.put('lastCheckInDate', date);
  }

  static String getLastCheckInDate() {
    final box = Hive.box(_settingsBox);
    return box.get('lastCheckInDate', defaultValue: '') as String;
  }

  static Future<void> saveLastCheckInMessage(String message) async {
    final box = Hive.box(_settingsBox);
    await box.put('lastCheckInMessage', message);
  }

  static String getLastCheckInMessage() {
    final box = Hive.box(_settingsBox);
    return box.get('lastCheckInMessage', defaultValue: '') as String;
  }

  // ── Notification settings ─────────────────────────────────────────────────
  static Future<void> saveNotificationSettings(Map<String, dynamic> s) async {
    final box = Hive.box(_settingsBox);
    await box.put('notifMorningEnabled',  s['morningEnabled']);
    await box.put('notifMorningHour',     s['morningHour']);
    await box.put('notifMorningMinute',   s['morningMinute']);
    await box.put('notifEveningEnabled',  s['eveningEnabled']);
    await box.put('notifEveningHour',     s['eveningHour']);
    await box.put('notifEveningMinute',   s['eveningMinute']);
    await box.put('notifPreTaskEnabled',  s['preTaskEnabled']);
  }

  static Map<String, dynamic> getNotificationSettings() {
    final box = Hive.box(_settingsBox);
    return {
      'morningEnabled':  box.get('notifMorningEnabled',  defaultValue: true),
      'morningHour':     box.get('notifMorningHour',     defaultValue: 7),
      'morningMinute':   box.get('notifMorningMinute',   defaultValue: 30),
      'eveningEnabled':  box.get('notifEveningEnabled',  defaultValue: true),
      'eveningHour':     box.get('notifEveningHour',     defaultValue: 21),
      'eveningMinute':   box.get('notifEveningMinute',   defaultValue: 0),
      'preTaskEnabled':  box.get('notifPreTaskEnabled',  defaultValue: true),
    };
  }

  // ── Emergency contacts ────────────────────────────────────────────────────
  static Future<void> saveEmergencyContacts(List<String> contacts) async {
    final box = Hive.box(_settingsBox);
    await box.put('emergencyContacts', contacts);
  }

  static List<String> getEmergencyContacts() {
    final box = Hive.box(_settingsBox);
    final raw = box.get('emergencyContacts', defaultValue: <String>[]);
    return List<String>.from(raw as List);
  }

  // ── Clear all data ────────────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await Hive.box(_cycleBox).clear();
    await Hive.box(_journalBox).clear();
    await Hive.box(_pointsBox).clear();
    await Hive.box(_settingsBox).clear();
  }
}