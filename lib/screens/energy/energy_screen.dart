import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/claude_service.dart';

class EnergyScreen extends ConsumerWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final cycle = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('Energy Levels')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EnergyBanner(cycle: cycle),
            const SizedBox(height: 16),
            const SakhiSectionHeader(title: "Today's tasks"),
            const SizedBox(height: 10),
            if (tasks.isEmpty)
              const SakhiEmptyState(
                emoji:    '✨',
                title:    'No tasks today',
                subtitle: 'Your calendar is clear — a good day to rest or plan ahead.',
              )
            else
              ...tasks.map((task) => _EnergyTaskCard(task: task, phase: cycle.phase)),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _EnergyBanner extends StatelessWidget {
  final CycleState cycle;
  const _EnergyBanner({required this.cycle});

  @override
  Widget build(BuildContext context) {
    final profile = _energyForPhase(cycle.phase);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [SakhiColors.deep, profile.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(cycle.phase.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Day ${cycle.dayOfCycle} — ${cycle.phase.label}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              const Text('Overall energy today',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        profile.color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border:       Border.all(color: profile.color.withOpacity(0.5)),
              ),
              child: Text(profile.overallLevel,
                  style: TextStyle(color: profile.color, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          _EnergyBar('Physical',  profile.physical,  profile.color),
          const SizedBox(height: 6),
          _EnergyBar('Cognitive', profile.cognitive, profile.color),
          const SizedBox(height: 6),
          _EnergyBar('Emotional', profile.emotional, profile.color),
          const SizedBox(height: 6),
          _EnergyBar('Social',    profile.social,    profile.color),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(child: Text(profile.generalTip,
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12.5, height: 1.5))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EnergyBar extends StatelessWidget {
  final String label;
  final double value;
  final Color  color;
  const _EnergyBar(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 72,
          child: Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.7),
                  fontSize: 11, fontWeight: FontWeight.w500))),
      Expanded(child: Stack(children: [
        Container(height: 6,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3))),
        FractionallySizedBox(widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: 6,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))),
      ])),
      const SizedBox(width: 8),
      Text('${(value * 100).round()}%',
          style: TextStyle(color: Colors.white.withOpacity(0.7),
              fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _EnergyTaskCard extends StatefulWidget {
  final Task       task;
  final CyclePhase phase;
  const _EnergyTaskCard({required this.task, required this.phase});

  @override
  State<_EnergyTaskCard> createState() => _EnergyTaskCardState();
}

class _EnergyTaskCardState extends State<_EnergyTaskCard> {
  late _TaskEnergyInfo _info;
  bool _loadingAI = false;
  bool _aiLoaded  = false;

  @override
  void initState() {
    super.initState();
    _info = _energyForTask(widget.task.title, widget.phase);
    _loadFromClaude();
  }

  Future<void> _loadFromClaude() async {
    if (!mounted) return;
    setState(() => _loadingAI = true);
    try {
      final result = await ClaudeService.getTaskEnergyInsight(
        taskName: widget.task.title,
        cycle:    CycleState(dayOfCycle: 0, phase: widget.phase, cycleLength: 28),
      );
      if (mounted && result.isNotEmpty &&
          (result['expectation'] ?? '').isNotEmpty &&
          (result['tip'] ?? '').isNotEmpty) {
        setState(() {
          _info = _TaskEnergyInfo(
            energyLabel: _info.energyLabel,
            emoji:       _info.emoji,
            badgeColor:  _info.badgeColor,
            expectation: result['expectation']!,
            tip:         result['tip']!,
          );
          _aiLoaded = true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingAI = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SakhiColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SakhiColors.petal),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.task.title, style: const TextStyle(fontSize: 14,
                fontWeight: FontWeight.w700, color: SakhiColors.deep)),
            const SizedBox(height: 2),
            Text(DateFormat('h:mm a').format(widget.task.time),
                style: const TextStyle(fontSize: 12, color: SakhiColors.lgray)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:        _info.badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: _info.badgeColor.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_info.emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(_info.energyLabel,
                  style: TextStyle(color: _info.badgeColor, fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        const Divider(height: 1, color: SakhiColors.petal),
        const SizedBox(height: 12),

        // Loading indicator while Claude is generating
        if (_loadingAI && !_aiLoaded)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5,
                      color: SakhiColors.rose.withOpacity(0.5))),
              const SizedBox(width: 8),
              Text('Getting personalised insight...',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                      color: SakhiColors.lgray.withOpacity(0.7))),
            ]),
          ),

        _InfoRow(icon: Icons.bolt_outlined, label: 'What to expect',
            text: _info.expectation, color: _info.badgeColor),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.lightbulb_outline, label: 'Tip',
            text: _info.tip, color: SakhiColors.gold),

        // Badge when Claude generated the content
        if (_aiLoaded) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        SakhiColors.rose.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border:       Border.all(color: SakhiColors.rose.withOpacity(0.2)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.auto_awesome, color: SakhiColors.rose, size: 10),
              SizedBox(width: 4),
              Text('Personalised by Sakhi AI',
                  style: TextStyle(fontSize: 9, color: SakhiColors.rose,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   text;
  final Color    color;
  const _InfoRow({required this.icon, required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: RichText(text: TextSpan(children: [
        TextSpan(text: '$label: ',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        TextSpan(text: text,
            style: const TextStyle(color: SakhiColors.gray, fontSize: 12, height: 1.5)),
      ]))),
    ]);
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class _EnergyProfile {
  final String overallLevel;
  final Color  color, gradientEnd;
  final double physical, cognitive, emotional, social;
  final String generalTip;
  const _EnergyProfile({required this.overallLevel, required this.color,
    required this.gradientEnd, required this.physical, required this.cognitive,
    required this.emotional, required this.social, required this.generalTip});
}

class _TaskEnergyInfo {
  final String energyLabel, emoji, expectation, tip;
  final Color  badgeColor;
  const _TaskEnergyInfo({required this.energyLabel, required this.emoji,
    required this.badgeColor, required this.expectation, required this.tip});
}

_EnergyProfile _energyForPhase(CyclePhase phase) {
  switch (phase) {
    case CyclePhase.menstrual:
      return const _EnergyProfile(overallLevel: 'Low', color: Color(0xFF8B2560),
          gradientEnd: Color(0xFF5A1040), physical: 0.30, cognitive: 0.45,
          emotional: 0.40, social: 0.35,
          generalTip: 'Protect your energy today. Tackle the one most important task first, then give yourself permission to rest. You are not underperforming — your body is doing significant work.');
    case CyclePhase.follicular:
      return const _EnergyProfile(overallLevel: 'Rising', color: Color(0xFF1A3A8A),
          gradientEnd: Color(0xFF1A2560), physical: 0.70, cognitive: 0.80,
          emotional: 0.75, social: 0.70,
          generalTip: 'Great day to start something new or tackle work that needs fresh thinking. Your brain is sharpening — use it for your most ambitious tasks.');
    case CyclePhase.ovulatory:
      return const _EnergyProfile(overallLevel: 'Peak', color: Color(0xFF1A5E30),
          gradientEnd: Color(0xFF0D3A1E), physical: 0.90, cognitive: 0.85,
          emotional: 0.90, social: 0.95,
          generalTip: 'This is your power window. Schedule your most important conversations, presentations, and decisions today. Communication and confidence are at their highest.');
    case CyclePhase.luteal:
      return const _EnergyProfile(overallLevel: 'Steady', color: Color(0xFF7A4800),
          gradientEnd: Color(0xFF4A2C00), physical: 0.55, cognitive: 0.70,
          emotional: 0.50, social: 0.45,
          generalTip: 'Detail and analytical thinking are strong right now. Best for finishing and refining work. Lean into focused solo work rather than high-stakes social situations.');
  }
}

_TaskEnergyInfo _energyForTask(String taskTitle, CyclePhase phase) {
  final lower = taskTitle.toLowerCase();
  final isMeeting      = lower.contains('meet') || lower.contains('standup') || lower.contains('sync') || lower.contains('call');
  final isPresentation = lower.contains('present') || lower.contains('pitch') || lower.contains('demo');
  final isReview       = lower.contains('review') || lower.contains('feedback') || lower.contains('check');
  final isCreative     = lower.contains('design') || lower.contains('creative') || lower.contains('brainstorm') || lower.contains('plan');
  final isAdmin        = lower.contains('email') || lower.contains('admin') || lower.contains('report') || lower.contains('wrap');
  final isExercise     = lower.contains('gym') || lower.contains('workout') || lower.contains('run') || lower.contains('yoga');
  final isLunch        = lower.contains('lunch') || lower.contains('break') || lower.contains('dinner');
  final isNegotiation  = lower.contains('negotiat') || lower.contains('salary') || lower.contains('interview');

  switch (phase) {
    case CyclePhase.menstrual:
      if (isExercise) return const _TaskEnergyInfo(energyLabel: 'Take it easy', emoji: '🌿',
          badgeColor: Color(0xFF8B2560),
          expectation: 'Physical energy is low. Pushing hard may increase cramps and fatigue.',
          tip: 'Swap intense cardio for a gentle walk or yoga. Movement still helps — just softer today.');
      if (isMeeting || isPresentation) return const _TaskEnergyInfo(energyLabel: 'Manageable', emoji: '🌙',
          badgeColor: Color(0xFF8B2560),
          expectation: 'Social energy is lower. You may feel quieter or less expressive than usual.',
          tip: 'Prepare key points in advance so you\'re not improvising. Keep it brief and focused.');
      if (isAdmin || isReview) return const _TaskEnergyInfo(energyLabel: 'Good fit', emoji: '✅',
          badgeColor: Color(0xFF1A5C36),
          expectation: 'Reflective thinking is heightened during menstruation. Admin and review tasks suit this energy.',
          tip: 'This is a genuinely good day for careful, methodical work. Trust your instincts on what needs changing.');
      return const _TaskEnergyInfo(energyLabel: 'Low energy', emoji: '🌙',
          badgeColor: Color(0xFF8B2560),
          expectation: 'Energy reserves are lower. Expect to need more breaks than usual.',
          tip: 'Do the most important part first, then rest. One focused hour beats four exhausted ones.');

    case CyclePhase.follicular:
      if (isCreative || isPresentation) return const _TaskEnergyInfo(energyLabel: 'Perfect timing', emoji: '⚡',
          badgeColor: Color(0xFF1A3A8A),
          expectation: 'Estrogen is rising, boosting creative and strategic thinking. Ideas will flow easily.',
          tip: 'Don\'t hold back on big ideas today. This phase is made for ambitious thinking — go further than usual.');
      if (isMeeting) return const _TaskEnergyInfo(energyLabel: 'Good', emoji: '👍',
          badgeColor: Color(0xFF1A3A8A),
          expectation: 'Social confidence is building. You\'ll find it easier to contribute and think on your feet.',
          tip: 'A good day to take the lead in discussions or raise something you\'ve been putting off.');
      if (isExercise) return const _TaskEnergyInfo(energyLabel: 'Good energy', emoji: '🏃',
          badgeColor: Color(0xFF1A3A8A),
          expectation: 'Physical energy is increasing. Your body is ready to build strength and endurance.',
          tip: 'Gradually increase intensity this week. Recovery is better now — a good time to push a little harder.');
      return const _TaskEnergyInfo(energyLabel: 'Rising', emoji: '📈',
          badgeColor: Color(0xFF1A3A8A),
          expectation: 'Energy and focus are building. Most tasks will feel more manageable than last week.',
          tip: 'Use this window to start anything you\'ve been putting off. Starting is easiest when energy is rising.');

    case CyclePhase.ovulatory:
      if (isNegotiation || isPresentation) return const _TaskEnergyInfo(energyLabel: 'Ideal day', emoji: '🌟',
          badgeColor: Color(0xFF1A5C36),
          expectation: 'Communication confidence is at its peak. You will come across as articulate and compelling.',
          tip: 'This is exactly the right day for this. Walk in prepared and trust yourself — your verbal reasoning is sharper than usual.');
      if (isMeeting || isReview) return const _TaskEnergyInfo(energyLabel: 'Peak', emoji: '🌟',
          badgeColor: Color(0xFF1A5C36),
          expectation: 'Social energy and empathy are highest. Collaboration feels natural and rewarding.',
          tip: 'Great day to give feedback, resolve tensions, or have a difficult conversation you\'ve been delaying.');
      if (isExercise) return const _TaskEnergyInfo(energyLabel: 'High energy', emoji: '💪',
          badgeColor: Color(0xFF1A5C36),
          expectation: 'Physical strength and pain tolerance are both at their highest.',
          tip: 'Push for a personal best today if you want one. Your body is primed for peak performance.');
      return const _TaskEnergyInfo(energyLabel: 'Peak energy', emoji: '⭐',
          badgeColor: Color(0xFF1A5C36),
          expectation: 'All energy dimensions are high. You\'ll feel motivated, clear-headed, and confident.',
          tip: 'Do your most important work today. This window lasts about 48 hours — make the most of it.');

    case CyclePhase.luteal:
      if (isAdmin || isReview) return const _TaskEnergyInfo(energyLabel: 'Strong fit', emoji: '🎯',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Detail-orientation and analytical thinking are heightened in the luteal phase.',
          tip: 'Lean into the detail work. You\'ll catch things you\'d normally miss. A great day for editing and refining.');
      if (isMeeting || isPresentation) return const _TaskEnergyInfo(energyLabel: 'Moderate', emoji: '⚖️',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Social energy is declining. You may feel less enthusiastic about group settings.',
          tip: 'Prepare more than usual — having bullet points means you won\'t need to improvise when energy is lower.');
      if (isExercise) return const _TaskEnergyInfo(energyLabel: 'Moderate', emoji: '🚶',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Endurance may be slightly lower, especially in late luteal phase.',
          tip: 'Moderate intensity works well — think steady cardio or strength at 70-80%. Avoid maxing out this week.');
      if (isCreative) return const _TaskEnergyInfo(energyLabel: 'Finishing mode', emoji: '✏️',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Better at refining and completing creative work than starting fresh.',
          tip: 'Work on finishing and polishing existing projects rather than starting from scratch.');
      if (isLunch) return const _TaskEnergyInfo(energyLabel: 'Use it wisely', emoji: '🥗',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Your body may crave comfort foods — cravings are real and hormonally driven in this phase.',
          tip: 'Magnesium-rich foods like dark chocolate, nuts, and leafy greens genuinely help with late luteal symptoms.');
      return const _TaskEnergyInfo(energyLabel: 'Steady', emoji: '🔋',
          badgeColor: Color(0xFF7A4800),
          expectation: 'Energy is steady but not high. Best for tasks requiring care and focus.',
          tip: 'Work in focused blocks with proper breaks. Concentration can be strong in luteal phase — use that.');
  }
}