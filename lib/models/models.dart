// ── Cycle phase ───────────────────────────────────────────────────────────────
enum CyclePhase { menstrual, follicular, ovulatory, luteal }

extension CyclePhaseX on CyclePhase {
  String get label {
    switch (this) {
      case CyclePhase.menstrual:  return 'Menstrual';
      case CyclePhase.follicular: return 'Follicular';
      case CyclePhase.ovulatory:  return 'Ovulatory';
      case CyclePhase.luteal:     return 'Luteal';
    }
  }

  String get days {
    switch (this) {
      case CyclePhase.menstrual:  return 'Days 1–5';
      case CyclePhase.follicular: return 'Days 6–13';
      case CyclePhase.ovulatory:  return 'Days 14–16';
      case CyclePhase.luteal:     return 'Days 17–28';
    }
  }

  String get tagline {
    switch (this) {
      case CyclePhase.menstrual:  return 'Rest & reflect';
      case CyclePhase.follicular: return 'Start & create';
      case CyclePhase.ovulatory:  return 'Perform & lead';
      case CyclePhase.luteal:     return 'Finish & detail';
    }
  }

  String get description {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Energy is low and intuition is high. Best for reflection, admin work, and gentle tasks.';
      case CyclePhase.follicular:
        return 'Rising energy and optimism. Best for new projects, learning, and strategic planning.';
      case CyclePhase.ovulatory:
        return 'Peak communication and confidence. Best for presentations, negotiations, and interviews.';
      case CyclePhase.luteal:
        return 'Detail-oriented and analytical. Best for editing, finishing projects, and deep work.';
    }
  }

  String get emoji {
    switch (this) {
      case CyclePhase.menstrual:  return '🌑';
      case CyclePhase.follicular: return '🌒';
      case CyclePhase.ovulatory:  return '🌕';
      case CyclePhase.luteal:     return '🌖';
    }
  }

  int get pointMultiplier {
    switch (this) {
      case CyclePhase.menstrual:  return 2;
      case CyclePhase.follicular: return 1;
      case CyclePhase.ovulatory:  return 1;
      case CyclePhase.luteal:     return 1;
    }
  }
}

// ── Task ──────────────────────────────────────────────────────────────────────
class Task {
  final String id;
  final String title;
  final DateTime time;
  bool completed;
  int? rating; // 1–5

  Task({
    required this.id,
    required this.title,
    required this.time,
    this.completed = false,
    this.rating,
  });
}

// ── Journal entry ─────────────────────────────────────────────────────────────
class JournalEntry {
  final DateTime date;
  final List<Task> tasks;
  final String notes;
  final CyclePhase phase;

  JournalEntry({
    required this.date,
    required this.tasks,
    required this.notes,
    required this.phase,
  });
}

// ── Chat message ──────────────────────────────────────────────────────────────
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

// ── Resilience points ─────────────────────────────────────────────────────────
class ResilienceData {
  final int totalPoints;
  final int journalStreak;
  final int tasksCompletedThisCycle;
  final List<int> weeklyPoints; // last 7 days

  ResilienceData({
    required this.totalPoints,
    required this.journalStreak,
    required this.tasksCompletedThisCycle,
    required this.weeklyPoints,
  });
}
