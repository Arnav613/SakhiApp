import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/health_alerts_widget.dart';
import '../../widgets/symptom_log_sheet.dart';

class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _prevMonth() => setState(() =>
  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() => setState(() =>
  _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final cycle = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('My Cycle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Current phase card ───────────────────────────────────
            _CurrentPhaseCard(cycle: cycle),
            const SizedBox(height: 16),

            // ── Calendar ─────────────────────────────────────────────
            _CycleCalendar(
              cycle:        cycle,
              displayMonth: _displayMonth,
              onPrevMonth:  _prevMonth,
              onNextMonth:  _nextMonth,
            ),
            const SizedBox(height: 16),

            // ── Legend ────────────────────────────────────────────────
            _Legend(),
            const SizedBox(height: 16),

            // ── Health alerts ─────────────────────────────────────────
            const SakhiSectionHeader(title: 'Health patterns'),
            const SizedBox(height: 10),
            const HealthAlertsSection(),
            const SizedBox(height: 16),

            // ── Log period button ─────────────────────────────────────
            _LogPeriodButton(),
            const SizedBox(height: 16),

            // ── Phase guide ───────────────────────────────────────────
            const SakhiSectionHeader(title: 'Phase guide'),
            const SizedBox(height: 10),
            ...CyclePhase.values.map((p) => _PhaseCard(
              phase:     p,
              isCurrent: p == cycle.phase,
            )),
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

  Color get _bg {
    switch (cycle.phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrual;
      case CyclePhase.follicular: return SakhiColors.follicular;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatory;
      case CyclePhase.luteal:     return SakhiColors.luteal;
    }
  }

  Color get _fg {
    switch (cycle.phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrualDark;
      case CyclePhase.follicular: return SakhiColors.follicularDark;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatoryDark;
      case CyclePhase.luteal:     return SakhiColors.lutealDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        _bg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: _fg.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(cycle.phase.emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${cycle.dayOfCycle} of ${cycle.cycleLength}',
                    style: TextStyle(fontSize: 12, color: _fg.withOpacity(0.7),
                        fontWeight: FontWeight.w500)),
                Text(cycle.phase.label,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _fg)),
                const SizedBox(height: 2),
                Text(cycle.phase.tagline,
                    style: TextStyle(fontSize: 12, color: _fg.withOpacity(0.8))),
                const SizedBox(height: 6),
                Text(cycle.phase.description,
                    style: TextStyle(fontSize: 12, color: _fg.withOpacity(0.7), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cycle calendar ────────────────────────────────────────────────────────────
class _CycleCalendar extends StatelessWidget {
  final CycleState  cycle;
  final DateTime    displayMonth;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  const _CycleCalendar({
    required this.cycle,
    required this.displayMonth,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  // Work out which phase a given calendar date falls in
  _DayInfo _infoForDate(DateTime date) {
    if (cycle.lastPeriodStart == null) {
      return _DayInfo(phase: null, isToday: _isToday(date), isFuture: date.isAfter(DateTime.now()));
    }

    final start      = cycle.lastPeriodStart!;
    final cycleLen   = cycle.cycleLength;

    // Calculate day number in the current (or past/future) cycle
    final diff = date.difference(DateTime(start.year, start.month, start.day)).inDays;

    // Could be negative (before last period) or very large (far in future)
    int dayInCycle;
    if (diff < 0) {
      // Before last period — figure out which cycle it was in
      final cyclesBefore = (diff.abs() / cycleLen).ceil();
      dayInCycle = diff + cyclesBefore * cycleLen;
    } else {
      dayInCycle = (diff % cycleLen) + 1;
    }

    CyclePhase phase;
    if (dayInCycle <= 5)       phase = CyclePhase.menstrual;
    else if (dayInCycle <= 13) phase = CyclePhase.follicular;
    else if (dayInCycle <= 16) phase = CyclePhase.ovulatory;
    else                       phase = CyclePhase.luteal;

    return _DayInfo(
      phase:    phase,
      dayNum:   dayInCycle,
      isToday:  _isToday(date),
      isFuture: date.isAfter(DateTime.now()),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  Color _phaseColor(_DayInfo info, {bool bg = true}) {
    if (info.phase == null) return SakhiColors.vblush;
    final opacity = info.isFuture ? 0.35 : 1.0;
    switch (info.phase!) {
      case CyclePhase.menstrual:
        return bg
            ? Color.lerp(SakhiColors.menstrual, SakhiColors.menstrualDark, info.isFuture ? 0.0 : 0.15)!
            : SakhiColors.menstrualDark;
      case CyclePhase.follicular:
        return bg
            ? Color.lerp(SakhiColors.follicular, SakhiColors.follicularDark, info.isFuture ? 0.0 : 0.1)!
            : SakhiColors.follicularDark;
      case CyclePhase.ovulatory:
        return bg
            ? Color.lerp(SakhiColors.ovulatory, SakhiColors.ovulatoryDark, info.isFuture ? 0.0 : 0.15)!
            : SakhiColors.ovulatoryDark;
      case CyclePhase.luteal:
        return bg
            ? Color.lerp(SakhiColors.luteal, SakhiColors.lutealDark, info.isFuture ? 0.0 : 0.1)!
            : SakhiColors.lutealDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstDay    = DateTime(displayMonth.year, displayMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);
    // Monday = 0 offset
    final startOffset = (firstDay.weekday - 1) % 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        SakhiColors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        children: [
          // ── Month nav ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon:       const Icon(Icons.chevron_left, color: SakhiColors.deep),
                onPressed:  onPrevMonth,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                  DateFormat('MMMM yyyy').format(displayMonth),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
              IconButton(
                icon:       const Icon(Icons.chevron_right, color: SakhiColors.deep),
                onPressed:  onNextMonth,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Day headers ──────────────────────────────────────────
          Row(
            children: ['M','T','W','T','F','S','S'].map((d) =>
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: SakhiColors.lgray)),
                  ),
                )
            ).toList(),
          ),
          const SizedBox(height: 8),

          // ── Calendar grid ────────────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics:    const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:   7,
              childAspectRatio: 1,
              mainAxisSpacing:  4,
              crossAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (ctx, index) {
              if (index < startOffset) return const SizedBox();

              final day  = index - startOffset + 1;
              final date = DateTime(displayMonth.year, displayMonth.month, day);
              final info = _infoForDate(date);
              final bg   = _phaseColor(info, bg: true);
              final fg   = info.phase != null
                  ? _phaseColor(info, bg: false)
                  : SakhiColors.lgray;

              return Container(
                decoration: BoxDecoration(
                  color:        info.isToday ? SakhiColors.deep : bg,
                  borderRadius: BorderRadius.circular(8),
                  border:       info.isToday
                      ? Border.all(color: SakhiColors.gold, width: 2)
                      : Border.all(color: fg.withOpacity(0.15)),
                ),
                child: Center(
                  child: Text('$day',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: info.isToday ? FontWeight.w700 : FontWeight.w500,
                        color:      info.isToday
                            ? Colors.white
                            : info.isFuture
                            ? fg.withOpacity(0.5)
                            : fg,
                      )),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayInfo {
  final CyclePhase? phase;
  final int dayNum;
  final bool isToday;
  final bool isFuture;

  _DayInfo({
    this.phase,
    this.dayNum = 1,
    required this.isToday,
    required this.isFuture,
  });
}

// ── Legend ────────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (SakhiColors.menstrual,  SakhiColors.menstrualDark,  'Menstrual'),
      (SakhiColors.follicular, SakhiColors.follicularDark, 'Follicular'),
      (SakhiColors.ovulatory,  SakhiColors.ovulatoryDark,  'Ovulatory'),
      (SakhiColors.luteal,     SakhiColors.lutealDark,      'Luteal'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color:        item.$1,
                borderRadius: BorderRadius.circular(3),
                border:       Border.all(color: item.$2.withOpacity(0.4)),
              ),
            ),
            const SizedBox(width: 4),
            Text(item.$3,
                style: const TextStyle(fontSize: 10, color: SakhiColors.lgray)),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Log period button ─────────────────────────────────────────────────────────
class _LogPeriodButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycle = ref.watch(cycleProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        SakhiColors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💧', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('Period tracking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: SakhiColors.deep)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
              cycle.lastPeriodStart != null
                  ? 'Last period started ${DateFormat('d MMM yyyy').format(cycle.lastPeriodStart!)}'
                  : 'No period logged yet',
              style: const TextStyle(fontSize: 12, color: SakhiColors.lgray)),
          const SizedBox(height: 14),

          // Start today button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _confirmLog(context, ref, DateTime.now()),
              style: ElevatedButton.styleFrom(
                backgroundColor: SakhiColors.menstrualDark,
                foregroundColor: Colors.white,
                padding:         const EdgeInsets.symmetric(vertical: 13),
                shape:           RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon:  const Icon(Icons.water_drop, size: 16),
              label: const Text('Period started today',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),

          // Pick a different date
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: SakhiColors.menstrualDark,
                side:            BorderSide(color: SakhiColors.menstrualDark.withOpacity(0.5)),
                padding:         const EdgeInsets.symmetric(vertical: 12),
                shape:           RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon:  const Icon(Icons.calendar_today_outlined, size: 15),
              label: const Text('Choose a different start date',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLog(BuildContext context, WidgetRef ref, DateTime date) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log period start'),
        content: Text(
            'Set ${DateFormat('d MMMM yyyy').format(date)} as your period start date? '
                'This will reset your cycle tracking from this day.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final previous = ref.read(cycleProvider);
              ref.read(cycleProvider.notifier).logPeriodStart(date);
              Navigator.pop(context);
              // Show symptom logging sheet
              showModalBottomSheet(
                context:            context,
                isScrollControlled: true,
                backgroundColor:    Colors.transparent,
                builder: (_) => SymptomLogSheet(
                  periodStartDate:      date,
                  previousCycleLength: previous.lastPeriodStart != null
                      ? DateTime.now().difference(previous.lastPeriodStart!).inDays
                      : null,
                  onSaved: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Period logged from ${DateFormat('d MMM').format(date)}'),
                      backgroundColor: SakhiColors.menstrualDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  },
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: SakhiColors.menstrualDark),
            child: const Text('Log period',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  DateTime.now(),
      firstDate:    DateTime.now().subtract(const Duration(days: 60)),
      lastDate:     DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary:   SakhiColors.menstrualDark,
            onPrimary: Colors.white,
            surface:   SakhiColors.vblush,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && context.mounted) {
      _confirmLog(context, ref, picked);
    }
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
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(
          color: isCurrent ? fg : fg.withOpacity(0.2),
          width: isCurrent ? 2   : 1,
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
                Row(children: [
                  Text(phase.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
                  const SizedBox(width: 8),
                  Text(phase.days,
                      style: TextStyle(fontSize: 11, color: fg.withOpacity(0.6))),
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
                ]),
                const SizedBox(height: 4),
                Text(phase.description,
                    style: TextStyle(fontSize: 12.5, color: fg.withOpacity(0.75), height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}