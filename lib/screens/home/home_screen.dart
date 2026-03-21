import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle   = ref.watch(cycleProvider);
    final tasks   = ref.watch(tasksProvider);
    final name    = ref.watch(userNameProvider);
    final points  = ref.watch(resilienceProvider);

    final now     = DateTime.now();
    final hour    = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            backgroundColor: SakhiColors.deep,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [SakhiColors.deep, Color(0xFF5A1A40)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$greeting, $name 🌸',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(DateFormat('EEEE, d MMMM').format(now),
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.65),
                                        fontSize: 13)),
                              ],
                            ),
                            // Points pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:        Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border:       Border.all(color: SakhiColors.gold.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: SakhiColors.gold, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${points.totalPoints}',
                                      style: const TextStyle(
                                          color: SakhiColors.gold,
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PhaseBadge(phase: cycle.phase, large: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Morning check-in card ─────────────────────────────────
                _MorningCheckIn(phase: cycle.phase, name: name),
                const SizedBox(height: 6),

                // ── Cycle ring card ────────────────────────────────────────
                _CycleRingCard(dayOfCycle: cycle.dayOfCycle, totalDays: cycle.cycleLength, phase: cycle.phase),
                const SizedBox(height: 6),

                // ── Today's tasks ──────────────────────────────────────────
                const SakhiSectionHeader(title: "Today's tasks"),
                const SizedBox(height: 8),
                ...tasks.take(4).map((task) => _TaskTile(task: task)),
                const SizedBox(height: 6),

                // ── Journal streak ─────────────────────────────────────────
                _StreakCard(streak: points.journalStreak),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Morning check-in card ─────────────────────────────────────────────────────
class _MorningCheckIn extends StatelessWidget {
  final dynamic phase;
  final String name;

  const _MorningCheckIn({required this.phase, required this.name});

  String get message {
    switch (phase.index) {
      case 0: return "Energy may be lower today — that's okay. Prioritise your most important task early and give yourself grace for the rest.";
      case 1: return "Your mind is sharp and creative today. A great day to start something new, plan ahead, or pitch an idea.";
      case 2: return "You're in your peak communication window. Walk into every conversation with confidence — this is your moment.";
      case 3: return "Detail and analysis are your strengths today. Perfect for reviewing, editing, and finishing strong.";
      default: return "Here for you today, as always. 🌸";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B1040), Color(0xFF5A1A40)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SakhiColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: SakhiColors.gold.withOpacity(0.4)),
                ),
                child: const Text('Sakhi says',
                    style: TextStyle(color: SakhiColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(message,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }
}

// ── Cycle ring card ───────────────────────────────────────────────────────────
class _CycleRingCard extends StatelessWidget {
  final int dayOfCycle;
  final int totalDays;
  final CyclePhase phase;

  const _CycleRingCard({
    required this.dayOfCycle,
    required this.totalDays,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final progress = dayOfCycle / totalDays;

    return SakhiCard(
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 80, height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value:       progress,
                  strokeWidth: 8,
                  backgroundColor: SakhiColors.petal.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(SakhiColors.rose),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayOfCycle',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: SakhiColors.deep)),
                    const Text('/ 28',
                        style: TextStyle(fontSize: 10, color: SakhiColors.lgray)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase.label,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
                const SizedBox(height: 3),
                Text(phase.days,
                    style: const TextStyle(fontSize: 12, color: SakhiColors.lgray)),
                const SizedBox(height: 6),
                Text(phase.tagline,
                    style: const TextStyle(
                        fontSize: 13, color: SakhiColors.rose, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Task tile ─────────────────────────────────────────────────────────────────
class _TaskTile extends ConsumerWidget {
  final dynamic task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        task.completed ? SakhiColors.blush : SakhiColors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: SakhiColors.petal),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(tasksProvider.notifier).completeTask(task.id),
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color:  task.completed ? SakhiColors.rose : SakhiColors.white,
                shape:  BoxShape.circle,
                border: Border.all(
                  color: task.completed ? SakhiColors.rose : SakhiColors.petal,
                  width: 2,
                ),
              ),
              child: task.completed
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(task.title,
                style: TextStyle(
                  fontSize:           14,
                  fontWeight:         FontWeight.w500,
                  color:              task.completed ? SakhiColors.lgray : SakhiColors.deep,
                  decoration:         task.completed ? TextDecoration.lineThrough : null,
                  decorationColor:    SakhiColors.lgray,
                )),
          ),
          Text(
            '${task.time.hour}:${task.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: SakhiColors.lgray),
          ),
        ],
      ),
    );
  }
}

// ── Streak card ───────────────────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return SakhiCard(
      color: SakhiColors.amberP,
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak day journal streak',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
              const SizedBox(height: 2),
              const Text('Keep it up — journal again tonight',
                  style: TextStyle(fontSize: 12, color: SakhiColors.lgray)),
            ],
          ),
        ],
      ),
    );
  }
}