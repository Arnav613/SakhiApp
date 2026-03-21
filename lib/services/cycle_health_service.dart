import 'package:flutter/material.dart';

// ── Cycle health pattern detector ─────────────────────────────────────────────
// This service analyses logged cycle data to flag patterns that may indicate
// a condition worth discussing with a doctor.
//
// IMPORTANT: This is NOT a diagnostic tool. It only flags patterns.
// Every alert includes a recommendation to see a healthcare professional.

class CycleHealthService {

  // ── Run all checks and return any alerts ──────────────────────────────────
  static List<HealthAlert> analyse(List<CycleRecord> records) {
    if (records.isEmpty) return [];

    final alerts = <HealthAlert>[];

    _checkIrregularCycles(records, alerts);
    _checkMissedPeriods(records, alerts);
    _checkChronicPain(records, alerts);
    _checkHeavyFlow(records, alerts);
    _checkCycleLengthTrend(records, alerts);

    return alerts;
  }

  // ── Check 1: Irregular cycles (possible PCOS) ─────────────────────────────
  static void _checkIrregularCycles(List<CycleRecord> records, List<HealthAlert> alerts) {
    if (records.length < 2) return;

    final recent = records.take(3).toList();
    final longCycles = recent.where((r) => r.cycleLength != null && r.cycleLength! > 35).length;
    final shortCycles = recent.where((r) => r.cycleLength != null && r.cycleLength! < 21).length;

    if (longCycles >= 2) {
      alerts.add(HealthAlert(
        id:         'irregular_long',
        title:      'Cycles longer than usual',
        body:       'Your last ${longCycles} cycles have been longer than 35 days. '
            'Irregular or infrequent periods can sometimes be a sign of hormonal '
            'imbalance, including PCOS. It\'s worth mentioning to your doctor.',
        suggestion: 'Track 1-2 more cycles and bring this data to your next appointment.',
        severity:   AlertSeverity.moderate,
        icon:       '🔄',
        condition:  'Possible hormonal imbalance / PCOS',
      ));
    }

    if (shortCycles >= 2) {
      alerts.add(HealthAlert(
        id:         'irregular_short',
        title:      'Cycles shorter than usual',
        body:       'Your last ${shortCycles} cycles have been shorter than 21 days. '
            'Very short cycles can indicate hormonal changes or thyroid issues '
            'and are worth discussing with a healthcare professional.',
        suggestion: 'Note if you\'re experiencing other symptoms like fatigue or mood changes.',
        severity:   AlertSeverity.moderate,
        icon:       '⏱️',
        condition:  'Possible hormonal imbalance',
      ));
    }
  }

  // ── Check 2: Missed periods ───────────────────────────────────────────────
  static void _checkMissedPeriods(List<CycleRecord> records, List<HealthAlert> alerts) {
    if (records.length < 2) return;

    final missed = records.take(3).where((r) => r.periodMissed == true).length;
    if (missed >= 1) {
      alerts.add(HealthAlert(
        id:         'missed_period',
        title:      'Missed period logged',
        body:       'You have logged ${missed == 1 ? "a missed period" : "$missed missed periods"} '
            'recently. While stress and lifestyle changes can cause this, '
            'a missed period is always worth a check-in with your doctor '
            'to rule out any underlying causes.',
        suggestion: 'If you\'ve missed 2 or more periods, see a doctor soon.',
        severity:   AlertSeverity.high,
        icon:       '📅',
        condition:  'Possible anovulation / hormonal disruption',
      ));
    }
  }

  // ── Check 3: Chronic pain (possible endometriosis) ────────────────────────
  static void _checkChronicPain(List<CycleRecord> records, List<HealthAlert> alerts) {
    if (records.length < 2) return;

    final recent = records.take(3).toList();
    final highPain = recent.where((r) =>
    r.painLevel != null && r.painLevel! >= 4).length;

    if (highPain >= 2) {
      alerts.add(HealthAlert(
        id:         'chronic_pain',
        title:      'Consistently high period pain',
        body:       'You have logged severe pain (4–5 out of 5) during ${highPain} recent cycles. '
            'While some discomfort is normal, consistently severe pain is not '
            'something to push through. It can be a sign of endometriosis '
            'or other conditions that are very treatable when caught early.',
        suggestion: 'Keep a pain diary and share it with your gynaecologist. '
            'Severe period pain is not something you have to just live with.',
        severity:   AlertSeverity.high,
        icon:       '⚠️',
        condition:  'Possible endometriosis / dysmenorrhea',
      ));
    }
  }

  // ── Check 4: Heavy flow (possible fibroids / anaemia risk) ────────────────
  static void _checkHeavyFlow(List<CycleRecord> records, List<HealthAlert> alerts) {
    if (records.length < 2) return;

    final recent = records.take(3).toList();
    final heavyFlow = recent.where((r) => r.flowLevel == FlowLevel.veryHeavy).length;

    if (heavyFlow >= 2) {
      alerts.add(HealthAlert(
        id:         'heavy_flow',
        title:      'Consistently very heavy flow',
        body:       'You have logged very heavy flow across ${heavyFlow} recent cycles. '
            'This can lead to iron deficiency and anaemia, and may sometimes '
            'indicate fibroids or other uterine conditions. It\'s worth '
            'getting a blood count and mentioning it to your doctor.',
        suggestion: 'Look out for fatigue, dizziness, or shortness of breath — '
            'these can be signs of anaemia from blood loss.',
        severity:   AlertSeverity.moderate,
        icon:       '💧',
        condition:  'Possible fibroids / anaemia risk',
      ));
    }
  }

  // ── Check 5: Cycle length trending longer or shorter ─────────────────────
  static void _checkCycleLengthTrend(List<CycleRecord> records, List<HealthAlert> alerts) {
    if (records.length < 3) return;

    final lengths = records.take(4)
        .where((r) => r.cycleLength != null)
        .map((r) => r.cycleLength!)
        .toList();

    if (lengths.length < 3) return;

    // Check if consistently trending longer
    bool trendingLonger = true;
    bool trendingShorter = true;
    for (int i = 0; i < lengths.length - 1; i++) {
      if (lengths[i] <= lengths[i + 1]) trendingLonger  = false;
      if (lengths[i] >= lengths[i + 1]) trendingShorter = false;
    }

    final delta = (lengths.first - lengths.last).abs();
    if (delta < 5) return; // only flag if the shift is meaningful

    if (trendingLonger && !alerts.any((a) => a.id == 'irregular_long')) {
      alerts.add(HealthAlert(
        id:         'trend_longer',
        title:      'Cycles gradually getting longer',
        body:       'Your cycle length has been increasing over the last few months. '
            'Gradual changes in cycle length can sometimes indicate thyroid '
            'changes or perimenopause onset, and are worth tracking carefully.',
        suggestion: 'Note any other changes — energy, weight, temperature sensitivity. '
            'Share the full picture with your doctor.',
        severity:   AlertSeverity.low,
        icon:       '📈',
        condition:  'Possible thyroid / hormonal shift',
      ));
    }

    if (trendingShorter && !alerts.any((a) => a.id == 'irregular_short')) {
      alerts.add(HealthAlert(
        id:         'trend_shorter',
        title:      'Cycles gradually getting shorter',
        body:       'Your cycle length has been decreasing over the last few months. '
            'This can sometimes signal hormonal changes and is worth '
            'discussing with your healthcare provider.',
        suggestion: 'Track any other symptoms and bring your cycle history to your next appointment.',
        severity:   AlertSeverity.low,
        icon:       '📉',
        condition:  'Possible hormonal shift',
      ));
    }
  }

  // ── Check if we have enough data to analyse ───────────────────────────────
  static bool hasEnoughData(List<CycleRecord> records) => records.length >= 2;

  // ── Generate medical export summary ──────────────────────────────────────
  static String generateDoctorSummary(List<CycleRecord> records, List<HealthAlert> alerts) {
    final buf = StringBuffer();
    buf.writeln('SAKHI CYCLE HEALTH SUMMARY');
    buf.writeln('Generated: ${DateTime.now().toString().split('.').first}');
    buf.writeln('');
    buf.writeln('CYCLE HISTORY (last ${records.length} cycles):');
    for (final r in records) {
      buf.write('• ${r.startDate.toString().split(' ').first}');
      if (r.cycleLength != null) buf.write(' — ${r.cycleLength} day cycle');
      if (r.painLevel != null)   buf.write(' — pain ${r.painLevel}/5');
      if (r.flowLevel != null)   buf.write(' — ${r.flowLevel!.label} flow');
      if (r.periodMissed == true) buf.write(' — MISSED');
      buf.writeln();
    }
    if (alerts.isNotEmpty) {
      buf.writeln('');
      buf.writeln('FLAGGED PATTERNS:');
      for (final a in alerts) {
        buf.writeln('• ${a.condition}: ${a.body}');
      }
    }
    buf.writeln('');
    buf.writeln('Note: This summary is generated by the Sakhi app for informational');
    buf.writeln('purposes only and does not constitute medical advice or diagnosis.');
    return buf.toString();
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class CycleRecord {
  final DateTime  startDate;
  final int?      cycleLength;
  final int?      painLevel;    // 1–5
  final FlowLevel? flowLevel;
  final bool?     periodMissed;
  final String?   notes;

  CycleRecord({
    required this.startDate,
    this.cycleLength,
    this.painLevel,
    this.flowLevel,
    this.periodMissed,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    'startDate':    startDate.toIso8601String(),
    'cycleLength':  cycleLength,
    'painLevel':    painLevel,
    'flowLevel':    flowLevel?.name,
    'periodMissed': periodMissed,
    'notes':        notes,
  };

  factory CycleRecord.fromMap(Map<String, dynamic> m) => CycleRecord(
    startDate:    DateTime.parse(m['startDate'] as String),
    cycleLength:  m['cycleLength'] as int?,
    painLevel:    m['painLevel']   as int?,
    flowLevel:    m['flowLevel'] != null
        ? FlowLevel.values.firstWhere((f) => f.name == m['flowLevel'])
        : null,
    periodMissed: m['periodMissed'] as bool?,
    notes:        m['notes']        as String?,
  );
}

enum FlowLevel {
  light, medium, heavy, veryHeavy;

  String get label {
    switch (this) {
      case FlowLevel.light:     return 'Light';
      case FlowLevel.medium:    return 'Medium';
      case FlowLevel.heavy:     return 'Heavy';
      case FlowLevel.veryHeavy: return 'Very heavy';
    }
  }

  String get emoji {
    switch (this) {
      case FlowLevel.light:     return '🩸';
      case FlowLevel.medium:    return '🩸🩸';
      case FlowLevel.heavy:     return '🩸🩸🩸';
      case FlowLevel.veryHeavy: return '🩸🩸🩸🩸';
    }
  }
}

enum AlertSeverity { low, moderate, high }

class HealthAlert {
  final String        id;
  final String        title;
  final String        body;
  final String        suggestion;
  final AlertSeverity severity;
  final String        icon;
  final String        condition;

  HealthAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.suggestion,
    required this.severity,
    required this.icon,
    required this.condition,
  });

  Color get color {
    switch (severity) {
      case AlertSeverity.low:      return const Color(0xFF1A3A8A);
      case AlertSeverity.moderate: return const Color(0xFF7A4800);
      case AlertSeverity.high:     return const Color(0xFF8B2560);
    }
  }

  Color get bgColor {
    switch (severity) {
      case AlertSeverity.low:      return const Color(0xFFEEF3FC);
      case AlertSeverity.moderate: return const Color(0xFFFFF8E8);
      case AlertSeverity.high:     return const Color(0xFFFEF0F4);
    }
  }
}