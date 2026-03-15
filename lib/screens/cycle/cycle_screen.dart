import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('My Cycle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current phase card ────────────────────────────────────────
            _CurrentPhaseCard(cycle: cycle),
            const SizedBox(height: 8),

            // ── Phase timeline ────────────────────────────────────────────
            const SakhiSectionHeader(title: 'Your cycle'),
            const SizedBox(height: 10),
            _PhaseTimeline(currentDay: cycle.dayOfCycle),
            const SizedBox(height: 20),

            // ── All phases ────────────────────────────────────────────────
            const SakhiSectionHeader(title: 'Phase guide'),
            const SizedBox(height: 10),
            ...CyclePhase.values.map((p) => _PhaseCard(
              phase:     p,
              isCurrent: p == cycle.phase,
            )),
            const SizedBox(height: 16),

            // ── Log period ────────────────────────────────────────────────
            SakhiGradientButton(
              label:  'Log period start today',
              icon:   Icons.water_drop_outlined,
              onTap:  () {
                ref.read(cycleProvider.notifier).logPeriodStart(DateTime.now());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Period logged — cycle reset to day 1'),
                    backgroundColor: SakhiColors.rose,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Current phase card ────────────────────────────────────────────────────────
class _CurrentPhaseCard extends StatelessWidget {
  final CycleState cycle;
  const _CurrentPhaseCard({required this.cycle});

  Color get phaseColor {
    switch (cycle.phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrualDark;
      case CyclePhase.follicular: return SakhiColors.follicularDark;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatoryDark;
      case CyclePhase.luteal:     return SakhiColors.lutealDark;
    }
  }

  Color get phaseBg {
    switch (cycle.phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrual;
      case CyclePhase.follicular: return SakhiColors.follicular;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatory;
      case CyclePhase.luteal:     return SakhiColors.luteal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: phaseBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: phaseColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(cycle.phase.emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${cycle.dayOfCycle} of ${cycle.cycleLength}',
                  style: TextStyle(
                    fontSize: 12, color: phaseColor.withOpacity(0.7), fontWeight: FontWeight.w500)),
                Text(cycle.phase.label,
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: phaseColor)),
                const SizedBox(height: 4),
                Text(cycle.phase.tagline,
                  style: TextStyle(
                    fontSize: 13, color: phaseColor.withOpacity(0.8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(cycle.phase.description,
                  style: TextStyle(
                    fontSize: 12.5, color: phaseColor.withOpacity(0.75), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Phase timeline ────────────────────────────────────────────────────────────
class _PhaseTimeline extends StatelessWidget {
  final int currentDay;
  const _PhaseTimeline({required this.currentDay});

  @override
  Widget build(BuildContext context) {
    return SakhiCard(
      child: Column(
        children: [
          // Day markers
          Row(
            children: List.generate(28, (i) {
              final day      = i + 1;
              final isCurrent = day == currentDay;
              final isPast   = day < currentDay;

              Color barColor;
              if (day <= 5)       barColor = SakhiColors.menstrualDark;
              else if (day <= 13) barColor = SakhiColors.follicularDark;
              else if (day <= 16) barColor = SakhiColors.ovulatoryDark;
              else                barColor = SakhiColors.lutealDark;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: isCurrent ? 28 : 16,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isPast || isCurrent
                          ? barColor
                          : barColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 4, height: 4,
                        decoration: const BoxDecoration(
                          color: SakhiColors.rose, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // Phase labels
          Row(
            children: [
              _PhaseLabel('Menstrual', 5/28, SakhiColors.menstrualDark),
              _PhaseLabel('Follicular', 8/28, SakhiColors.follicularDark),
              _PhaseLabel('Ovulatory', 3/28, SakhiColors.ovulatoryDark),
              _PhaseLabel('Luteal', 12/28, SakhiColors.lutealDark),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhaseLabel extends StatelessWidget {
  final String label;
  final double flex;
  final Color color;

  const _PhaseLabel(this.label, this.flex, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: (flex * 100).round(),
      child: Text(label,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis),
    );
  }
}

// ── Phase card ────────────────────────────────────────────────────────────────
class _PhaseCard extends StatelessWidget {
  final CyclePhase phase;
  final bool isCurrent;

  const _PhaseCard({required this.phase, required this.isCurrent});

  Color get bg {
    switch (phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrual;
      case CyclePhase.follicular: return SakhiColors.follicular;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatory;
      case CyclePhase.luteal:     return SakhiColors.luteal;
    }
  }

  Color get fg {
    switch (phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrualDark;
      case CyclePhase.follicular: return SakhiColors.follicularDark;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatoryDark;
      case CyclePhase.luteal:     return SakhiColors.lutealDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: isCurrent ? fg : fg.withOpacity(0.2),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(phase.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(phase.label,
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w700,
                        color:      fg)),
                    const SizedBox(width: 8),
                    Text(phase.days,
                      style: TextStyle(
                        fontSize: 11, color: fg.withOpacity(0.6))),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: fg, borderRadius: BorderRadius.circular(10)),
                        child: const Text('Now',
                          style: TextStyle(color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(phase.description,
                  style: TextStyle(
                    fontSize: 12.5, color: fg.withOpacity(0.75), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
