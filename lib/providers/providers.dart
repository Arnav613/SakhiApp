import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/calendar_service.dart';
import '../services/storage_service.dart';

// ── Cycle state ───────────────────────────────────────────────────────────────
class CycleState {
  final int dayOfCycle;
  final CyclePhase phase;
  final DateTime? lastPeriodStart;
  final int cycleLength;

  CycleState({
    this.dayOfCycle = 14,
    this.phase = CyclePhase.ovulatory,
    this.lastPeriodStart,
    this.cycleLength = 28,
  });

  CycleState copyWith({
    int? dayOfCycle,
    CyclePhase? phase,
    DateTime? lastPeriodStart,
    int? cycleLength,
  }) {
    return CycleState(
      dayOfCycle:      dayOfCycle      ?? this.dayOfCycle,
      phase:           phase           ?? this.phase,
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      cycleLength:     cycleLength     ?? this.cycleLength,
    );
  }
}

class CycleNotifier extends StateNotifier<CycleState> {
  CycleNotifier() : super(_loadInitialState()) {
    // Recalculate day from last period date on app open
    _recalculateDay();
  }

  static CycleState _loadInitialState() {
    final saved = StorageService.getCycleData();
    final phase = _phaseFromString(saved['phase'] as String);
    return CycleState(
      dayOfCycle:  saved['dayOfCycle']  as int,
      cycleLength: saved['cycleLength'] as int,
      phase:       phase,
    );
  }

  void _recalculateDay() {
    final saved       = StorageService.getCycleData();
    final dateStr     = saved['lastPeriodStart'] as String;
    if (dateStr.isEmpty) return;
    final lastPeriod  = DateTime.parse(dateStr);
    final day         = DateTime.now().difference(lastPeriod).inDays + 1;
    CyclePhase phase;
    if (day <= 5)       phase = CyclePhase.menstrual;
    else if (day <= 13) phase = CyclePhase.follicular;
    else if (day <= 16) phase = CyclePhase.ovulatory;
    else                phase = CyclePhase.luteal;
    state = state.copyWith(dayOfCycle: day, phase: phase);
    _save();
  }

  void logPeriodStart(DateTime date) {
    final day = DateTime.now().difference(date).inDays + 1;
    CyclePhase phase;
    if (day <= 5)       phase = CyclePhase.menstrual;
    else if (day <= 13) phase = CyclePhase.follicular;
    else if (day <= 16) phase = CyclePhase.ovulatory;
    else                phase = CyclePhase.luteal;
    state = state.copyWith(
      lastPeriodStart: date,
      dayOfCycle:      day,
      phase:           phase,
    );
    _save();
  }

  void updateCycleLength(int length) {
    state = state.copyWith(cycleLength: length);
    _save();
  }

  void _save() {
    StorageService.saveCycleData(
      dayOfCycle:      state.dayOfCycle,
      cycleLength:     state.cycleLength,
      phase:           state.phase.name,
      lastPeriodStart: state.lastPeriodStart?.toIso8601String() ?? '',
    );
  }

  static CyclePhase _phaseFromString(String s) {
    switch (s) {
      case 'menstrual':  return CyclePhase.menstrual;
      case 'follicular': return CyclePhase.follicular;
      case 'ovulatory':  return CyclePhase.ovulatory;
      case 'luteal':     return CyclePhase.luteal;
      default:           return CyclePhase.ovulatory;
    }
  }
}

final cycleProvider = StateNotifierProvider<CycleNotifier, CycleState>(
  (ref) => CycleNotifier(),
);

// ── Shield state ──────────────────────────────────────────────────────────────
class ShieldState {
  final bool isActive;
  final DateTime? activatedAt;
  final int checkInMinutes;
  final List<String> emergencyContacts;

  ShieldState({
    this.isActive = false,
    this.activatedAt,
    this.checkInMinutes = 30,
    this.emergencyContacts = const [],
  });

  ShieldState copyWith({
    bool? isActive,
    DateTime? activatedAt,
    int? checkInMinutes,
    List<String>? emergencyContacts,
  }) {
    return ShieldState(
      isActive:          isActive          ?? this.isActive,
      activatedAt:       activatedAt       ?? this.activatedAt,
      checkInMinutes:    checkInMinutes    ?? this.checkInMinutes,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }
}

class ShieldNotifier extends StateNotifier<ShieldState> {
  ShieldNotifier() : super(ShieldState(
    emergencyContacts: StorageService.getEmergencyContacts(),
  ));

  void activate() {
    state = state.copyWith(isActive: true, activatedAt: DateTime.now());
  }

  void deactivate() {
    state = state.copyWith(isActive: false, activatedAt: null);
  }

  void setCheckIn(int minutes) {
    state = state.copyWith(checkInMinutes: minutes);
  }

  void addContact(String contact) {
    final updated = [...state.emergencyContacts, contact];
    state = state.copyWith(emergencyContacts: updated);
    StorageService.saveEmergencyContacts(updated);
  }

  void removeContact(String contact) {
    final updated = state.emergencyContacts.where((c) => c != contact).toList();
    state = state.copyWith(emergencyContacts: updated);
    StorageService.saveEmergencyContacts(updated);
  }
}

final shieldProvider = StateNotifierProvider<ShieldNotifier, ShieldState>(
  (ref) => ShieldNotifier(),
);

// ── Chat messages ─────────────────────────────────────────────────────────────
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([
    ChatMessage(
      text: "Good morning! You're on Day 14 — ovulatory phase. Communication is your superpower today. You have a team meeting at 10am. Walk in with confidence 🌸",
      isUser: false,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ]);

  void addMessage(String text, bool isUser) {
    state = [
      ...state,
      ChatMessage(text: text, isUser: isUser, time: DateTime.now()),
    ];
  }

  void addSakhiResponse(String text) {
    state = [
      ...state,
      ChatMessage(text: text, isUser: false, time: DateTime.now()),
    ];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (ref) => ChatNotifier(),
);

// ── Tasks ─────────────────────────────────────────────────────────────────────
// ── Calendar-aware tasks provider ────────────────────────────────────────────
final calendarLoadingProvider = StateProvider<bool>((ref) => false);
final calendarPermissionProvider = StateProvider<bool>((ref) => false);

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>(
      (ref) => TasksNotifier(),
);

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([]) {
    _loadFromCalendar();
  }

  Future<void> _loadFromCalendar() async {
    // Import this at top of providers.dart:
    // import '../services/calendar_service.dart';
    final tasks = await CalendarService.getTodaysTasks();
    if (mounted) state = tasks;
  }

  Future<void> refresh() async {
    final tasks = await CalendarService.getTodaysTasks();
    if (mounted) state = tasks;
  }

  void completeTask(String id) {
    state = state.map((t) =>
    t.id == id ? (t..completed = !t.completed) : t
    ).toList();
  }

  void rateTask(String id, int rating) {
    state = state.map((t) => t.id == id ? (t..rating = rating) : t).toList();
  }
}

// ── Resilience points ─────────────────────────────────────────────────────────
final resilienceProvider = StateNotifierProvider<ResilienceNotifier, ResilienceData>(
  (ref) => ResilienceNotifier(),
);

class ResilienceNotifier extends StateNotifier<ResilienceData> {
  ResilienceNotifier() : super(_load());

  static ResilienceData _load() {
    final saved = StorageService.getPoints();
    return ResilienceData(
      totalPoints:             saved['totalPoints']             as int,
      journalStreak:           saved['journalStreak']           as int,
      tasksCompletedThisCycle: saved['tasksCompletedThisCycle'] as int,
      weeklyPoints:            saved['weeklyPoints']            as List<int>,
    );
  }

  void addPoints(int points) {
    final updated = ResilienceData(
      totalPoints:             state.totalPoints + points,
      journalStreak:           state.journalStreak,
      tasksCompletedThisCycle: state.tasksCompletedThisCycle + 1,
      weeklyPoints:            state.weeklyPoints,
    );
    state = updated;
    _save();
  }

  void incrementStreak() {
    final updated = ResilienceData(
      totalPoints:             state.totalPoints,
      journalStreak:           state.journalStreak + 1,
      tasksCompletedThisCycle: state.tasksCompletedThisCycle,
      weeklyPoints:            state.weeklyPoints,
    );
    state = updated;
    _save();
  }

  void _save() {
    StorageService.savePoints(
      totalPoints:             state.totalPoints,
      journalStreak:           state.journalStreak,
      tasksCompletedThisCycle: state.tasksCompletedThisCycle,
      weeklyPoints:            state.weeklyPoints,
    );
  }
}

// ── Journal entries ───────────────────────────────────────────────────────────
final journalProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>(
  (ref) => JournalNotifier(),
);

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier() : super([]);

  void addEntry(JournalEntry entry) {
    state = [entry, ...state];
  }
}

// ── Onboarding ────────────────────────────────────────────────────────────────
final onboardingCompleteProvider = StateProvider<bool>(
      (ref) => StorageService.getOnboardingComplete(),
);

// ── User name ─────────────────────────────────────────────────────────────────
final userNameProvider = StateProvider<String>(
      (ref) => StorageService.getUserName().isNotEmpty
      ? StorageService.getUserName()
      : 'there',
);
