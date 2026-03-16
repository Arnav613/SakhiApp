import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final TextEditingController _notesCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final tasks  = ref.read(tasksProvider);
    final cycle  = ref.read(cycleProvider);
    final points = ref.read(resilienceProvider);

    // Add journal entry
    ref.read(journalProvider.notifier).addEntry(JournalEntry(
      date:  DateTime.now(),
      tasks: tasks,
      notes: _notesCtrl.text,
      phase: cycle.phase,
    ));

    // Save to Hive
    StorageService.saveJournalEntry(
      date:        DateTime.now().toIso8601String(),
      phase:       cycle.phase.name,
      notes:       _notesCtrl.text,
      taskRatings: tasks.where((t) => t.rating != null).map((t) => {
        'title':  t.title,
        'rating': t.rating,
      }).toList(),
    );

    // Award Resilience Points
    final completed  = tasks.where((t) => t.rating != null).length;
    final multiplier = cycle.phase.pointMultiplier;
    final earned     = completed * 20 * multiplier;
    ref.read(resilienceProvider.notifier).addPoints(earned);
    ref.read(resilienceProvider.notifier).incrementStreak();

    setState(() => _submitted = true);
    _showCompletedDialog(earned, multiplier);
  }

  void _showCompletedDialog(int earned, int multiplier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Journal saved',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: SakhiColors.deep)),
            const SizedBox(height: 8),
            if (multiplier > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: SakhiColors.amberP,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${multiplier}x Resilience Bonus active',
                  style: const TextStyle(
                    color: SakhiColors.amber, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            const SizedBox(height: 8),
            Text('+$earned Resilience Points earned',
              style: const TextStyle(
                color: SakhiColors.rose, fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),
            const Text(
              'Sakhi will read this tonight and check in with you in the morning.',
              style: TextStyle(color: SakhiColors.lgray, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final cycle = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(
        title: const Text('Evening journal'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: SakhiColors.gold,
          labelColor:   SakhiColors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Rate your day'),
            Tab(text: 'Past entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Tonight's journal ────────────────────────────────────────
          _TodayJournal(
            tasks:      tasks,
            cycle:      cycle,
            notesCtrl:  _notesCtrl,
            submitted:  _submitted,
            onSubmit:   _submit,
          ),
          // ── Past entries ─────────────────────────────────────────────
          _PastEntries(),
        ],
      ),
    );
  }
}

// ── Tonight's journal ─────────────────────────────────────────────────────────
class _TodayJournal extends StatelessWidget {
  final List<Task> tasks;
  final CycleState cycle;
  final TextEditingController notesCtrl;
  final bool submitted;
  final VoidCallback onSubmit;

  const _TodayJournal({
    required this.tasks,
    required this.cycle,
    required this.notesCtrl,
    required this.submitted,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return const SakhiEmptyState(
        emoji:    '🌙',
        title:    'Journal saved',
        subtitle: 'Sakhi will read this overnight and check in with you tomorrow morning.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Phase context ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SakhiColors.blush,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SakhiColors.petal),
            ),
            child: Row(
              children: [
                Text(cycle.phase.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'re in your ${cycle.phase.label.toLowerCase()} phase today. '
                    '${cycle.phase.tagline}.',
                    style: const TextStyle(
                      fontSize: 13, color: SakhiColors.gray, height: 1.5)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Task ratings ─────────────────────────────────────────────
          const Text('How did each task go?',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 4),
          const Text('Takes about 60 seconds',
            style: TextStyle(fontSize: 12, color: SakhiColors.lgray)),
          const SizedBox(height: 12),
          ...tasks.map((t) => _TaskRatingRow(task: t)),
          const SizedBox(height: 20),

          // ── Notes ────────────────────────────────────────────────────
          const Text('Anything on your mind?',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 4),
          const Text('Optional — write as much or as little as you want.',
            style: TextStyle(fontSize: 12, color: SakhiColors.lgray)),
          const SizedBox(height: 12),
          TextField(
            controller: notesCtrl,
            maxLines:   6,
            decoration: const InputDecoration(
              hintText: 'Today I felt...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          // ── Submit ────────────────────────────────────────────────────
          if (cycle.phase == CyclePhase.menstrual)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: SakhiColors.amberP,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SakhiColors.amber.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('🔥', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('2x Resilience Points active today — you\'re in your '
                      'menstrual phase. Everything you do today counts double.',
                      style: TextStyle(fontSize: 12, color: SakhiColors.amber, height: 1.4)),
                  ),
                ],
              ),
            ),

          SakhiGradientButton(
            label:  'Save tonight\'s journal',
            icon:   Icons.check_circle_outline,
            onTap:  onSubmit,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Task rating row ───────────────────────────────────────────────────────────
class _TaskRatingRow extends ConsumerWidget {
  final Task task;
  const _TaskRatingRow({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        SakhiColors.white,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title,
            style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: SakhiColors.deep)),
          const SizedBox(height: 8),
          StarRating(
            initialRating: task.rating ?? 0,
            onRating: (r) => ref.read(tasksProvider.notifier).rateTask(task.id, r),
          ),
        ],
      ),
    );
  }
}

// ── Past entries ──────────────────────────────────────────────────────────────
class _PastEntries extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalProvider);

    if (entries.isEmpty) {
      return const SakhiEmptyState(
        emoji:    '📖',
        title:    'No entries yet',
        subtitle: 'Complete your first journal tonight — Sakhi will read it overnight.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final entry = entries[i];
        final avgRating = entry.tasks.isEmpty
          ? 0.0
          : entry.tasks
              .where((t) => t.rating != null)
              .fold(0, (sum, t) => sum + t.rating!) /
            entry.tasks.where((t) => t.rating != null).length;

        return SakhiCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
                  PhaseBadge(phase: entry.phase),
                ],
              ),
              if (avgRating > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Average: ',
                      style: TextStyle(fontSize: 12, color: SakhiColors.lgray)),
                    ...List.generate(5, (j) => Icon(
                      j < avgRating.round()
                        ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: SakhiColors.gold, size: 16)),
                  ],
                ),
              ],
              if (entry.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(entry.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13, color: SakhiColors.gray, height: 1.5)),
              ],
            ],
          ),
        );
      },
    );
  }
}
