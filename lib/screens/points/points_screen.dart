import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(resilienceProvider);
    final cycle  = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('Resilience Points')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Total points hero ─────────────────────────────────────
            _TotalPointsCard(points: points, cycle: cycle),
            const SizedBox(height: 8),

            // ── Weekly bar chart ──────────────────────────────────────
            _WeeklyChart(weeklyPoints: points.weeklyPoints),
            const SizedBox(height: 8),

            // ── Stats row ─────────────────────────────────────────────
            _StatsRow(points: points),
            const SizedBox(height: 20),

            // ── How points work ───────────────────────────────────────
            _HowPointsWork(),
            const SizedBox(height: 20),

            // ── Monthly report card ───────────────────────────────────
            _MonthlyReportCard(points: points, cycle: cycle),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Total points card ─────────────────────────────────────────────────────────
class _TotalPointsCard extends StatelessWidget {
  final ResilienceData points;
  final CycleState cycle;

  const _TotalPointsCard({required this.points, required this.cycle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SakhiColors.deep, Color(0xFF6A1A50)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text('Total Resilience Points',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.star_rounded, color: SakhiColors.gold, size: 32),
              const SizedBox(width: 8),
              Text('${points.totalPoints}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 52, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          if (cycle.phase == CyclePhase.menstrual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: SakhiColors.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: SakhiColors.gold.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text('2x bonus active — menstrual phase',
                    style: TextStyle(
                      color: SakhiColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  final List<int> weeklyPoints;

  const _WeeklyChart({required this.weeklyPoints});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = weeklyPoints.isEmpty ? 1 : weeklyPoints.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SakhiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This week',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(weeklyPoints.length, (i) {
              final isToday = i == DateTime.now().weekday - 1;
              final height  = maxVal > 0
                ? (weeklyPoints[i] / maxVal * 80).clamp(4.0, 80.0)
                : 4.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${weeklyPoints[i]}',
                    style: TextStyle(
                      fontSize:   9,
                      color:      isToday ? SakhiColors.rose : SakhiColors.lgray,
                      fontWeight: isToday ? FontWeight.w700  : FontWeight.w400)),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve:    Curves.easeOut,
                    width:    28,
                    height:   height,
                    decoration: BoxDecoration(
                      color: isToday ? SakhiColors.rose : SakhiColors.blush,
                      borderRadius: BorderRadius.circular(4),
                      border: isToday
                        ? null
                        : Border.all(color: SakhiColors.petal),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[i],
                    style: TextStyle(
                      fontSize:   10,
                      color:      isToday ? SakhiColors.deep : SakhiColors.lgray,
                      fontWeight: isToday ? FontWeight.w700  : FontWeight.w400)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final ResilienceData points;
  const _StatsRow({required this.points});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatBox(
          emoji: '🔥', value: '${points.journalStreak}', label: 'Journal streak')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(
          emoji: '✅', value: '${points.tasksCompletedThisCycle}', label: 'Tasks this cycle')),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatBox({required this.emoji, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SakhiColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(value,
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 2),
          Text(label,
            style: const TextStyle(fontSize: 11, color: SakhiColors.lgray),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── How points work ───────────────────────────────────────────────────────────
class _HowPointsWork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Complete a task', '20 pts', '40 pts on period'),
      ('Rate a task in journal', '10 pts', '20 pts on period'),
      ('Complete full journal', '30 pts', '60 pts on period'),
      ('Journal streak bonus', '+10 per day', '+20 per day'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SakhiColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How points work',
            style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 4),
          const Text('Tasks completed during your menstrual phase earn double — because showing up when you\'re depleted is worth more.',
            style: TextStyle(fontSize: 12, color: SakhiColors.lgray, height: 1.5)),
          const SizedBox(height: 14),
          // Header
          Row(children: const [
            Expanded(child: Text('Action',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SakhiColors.lgray))),
            SizedBox(width: 8),
            Text('Normal',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SakhiColors.lgray)),
            SizedBox(width: 16),
            Text('🩸 Period',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: SakhiColors.rose)),
          ]),
          const Divider(height: 16, color: SakhiColors.petal),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: Text(r.$1,
                style: const TextStyle(fontSize: 13, color: SakhiColors.gray))),
              const SizedBox(width: 8),
              Text(r.$2,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SakhiColors.deep)),
              const SizedBox(width: 10),
              Text(r.$3,
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: SakhiColors.rose)),
            ]),
          )),
        ],
      ),
    );
  }
}

// ── Monthly report card ───────────────────────────────────────────────────────
class _MonthlyReportCard extends StatelessWidget {
  final ResilienceData points;
  final CycleState cycle;

  const _MonthlyReportCard({required this.points, required this.cycle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SakhiColors.blush, SakhiColors.vblush],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📋', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Monthly Cycle Report Card',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
            ],
          ),
          const SizedBox(height: 12),
          _ReportRow('Current phase', cycle.phase.label, cycle.phase.emoji),
          _ReportRow('Day of cycle', 'Day ${cycle.dayOfCycle}', '🌙'),
          _ReportRow('Points this cycle', '${points.totalPoints}', '⭐'),
          _ReportRow('Tasks completed', '${points.tasksCompletedThisCycle}', '✅'),
          _ReportRow('Journal streak', '${points.journalStreak} days', '🔥'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SakhiColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Sakhi\'s note: You\'re doing well this cycle. '
              'Remember — showing up on the hard days matters more than perfect days.',
              style: TextStyle(
                fontSize: 12.5, color: SakhiColors.gray, height: 1.5,
                fontStyle: FontStyle.italic)),
          )
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _ReportRow(this.label, this.value, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
            style: const TextStyle(fontSize: 13, color: SakhiColors.lgray))),
          Text(value,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: SakhiColors.deep)),
        ],
      ),
    );
  }
}
