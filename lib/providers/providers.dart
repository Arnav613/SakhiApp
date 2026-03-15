import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';

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
  CycleNotifier() : super(CycleState(lastPeriodStart: DateTime.now().subtract(const Duration(days: 13))));

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
  }

  void updateCycleLength(int length) {
    state = state.copyWith(cycleLength: length);
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
  ShieldNotifier() : super(ShieldState());

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
  }

  void removeContact(String contact) {
    final updated = state.emergencyContacts.where((c) => c != contact).toList();
    state = state.copyWith(emergencyContacts: updated);
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
final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>(
  (ref) => TasksNotifier(),
);

class TasksNotifier extends StateNotifier<List<Task>> {
  TasksNotifier() : super([
    Task(id: '1', title: 'Team standup', time: DateTime.now().copyWith(hour: 9, minute: 30)),
    Task(id: '2', title: 'Quarterly review', time: DateTime.now().copyWith(hour: 11, minute: 0)),
    Task(id: '3', title: 'Lunch with Priya', time: DateTime.now().copyWith(hour: 13, minute: 0)),
    Task(id: '4', title: 'Design review', time: DateTime.now().copyWith(hour: 15, minute: 30)),
    Task(id: '5', title: 'Reply to emails', time: DateTime.now().copyWith(hour: 17, minute: 0)),
  ]);

  void completeTask(String id) {
    state = state.map((t) => t.id == id ? (t..completed = true) : t).toList();
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
  ResilienceNotifier() : super(ResilienceData(
    totalPoints:              340,
    journalStreak:            5,
    tasksCompletedThisCycle:  12,
    weeklyPoints:             [20, 35, 40, 20, 60, 80, 45],
  ));

  void addPoints(int points) {
    state = ResilienceData(
      totalPoints:              state.totalPoints + points,
      journalStreak:            state.journalStreak,
      tasksCompletedThisCycle:  state.tasksCompletedThisCycle + 1,
      weeklyPoints:             state.weeklyPoints,
    );
  }

  void incrementStreak() {
    state = ResilienceData(
      totalPoints:              state.totalPoints,
      journalStreak:            state.journalStreak + 1,
      tasksCompletedThisCycle:  state.tasksCompletedThisCycle,
      weeklyPoints:             state.weeklyPoints,
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
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

// ── User name ─────────────────────────────────────────────────────────────────
final userNameProvider = StateProvider<String>((ref) => 'Ananya');
