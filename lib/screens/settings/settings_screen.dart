import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakhi/models/models.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/background_service.dart';
import '../../services/notifications_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final cycle    = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Notifications ─────────────────────────────────────────
            _SectionHeader('Notifications'),
            _SettingsTile(
              icon:  Icons.notifications_outlined,
              title: 'Notifications',
              value: 'Morning, evening & pre-task',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(height: 8),
            _SectionHeader('Demo notifications'),
            _TestNotificationButton(),
            _TestEveningButton(),
            _TestPreTaskButton(),
            const SizedBox(height: 20),

            // ── Profile ───────────────────────────────────────────────
            _SectionHeader('Profile'),
            _SettingsTile(
              icon:  Icons.person_outline,
              title: 'Name',
              value: userName,
              onTap: () => _editName(context, ref, userName),
            ),
            _SettingsTile(
              icon:  Icons.water_drop_outlined,
              title: 'Cycle length',
              value: '${cycle.cycleLength} days',
              onTap: () => _editCycleLength(context, ref, cycle.cycleLength),
            ),
            const SizedBox(height: 20),

            // ── About ─────────────────────────────────────────────────
            _SectionHeader('About'),
            _SettingsTile(
              icon:  Icons.info_outline,
              title: 'Version',
              value: '1.0.0',
            ),
            _SettingsTile(
              icon:  Icons.lock_outline,
              title: 'Privacy',
              value: 'All data stored on device',
            ),
            const SizedBox(height: 20),

            // ── Danger zone ───────────────────────────────────────────
            _SectionHeader('Data'),
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(14),
                border:       Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Reset all data',
                      style: TextStyle(
                          fontSize:   15,
                          fontWeight: FontWeight.w700,
                          color:      Colors.red)),
                  const SizedBox(height: 4),
                  const Text(
                      'Clears everything — name, cycle data, journal entries, and points. '
                          'You will go back to the onboarding screen. This cannot be undone.',
                      style: TextStyle(fontSize: 12, color: Colors.red, height: 1.5)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _confirmReset(context, ref),
                      child: const Text('Reset all data',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Edit name dialog ──────────────────────────────────────────────────────
  void _editName(BuildContext context, WidgetRef ref, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller:  ctrl,
          autofocus:   true,
          decoration:  const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  ref.read(userNameProvider.notifier).state = ctrl.text.trim();
                  StorageService.saveUserName(ctrl.text.trim());
                }
                Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  // ── Edit cycle length dialog ──────────────────────────────────────────────
  void _editCycleLength(BuildContext context, WidgetRef ref, int current) {
    int selected = current;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cycle length'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selected days',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: SakhiColors.rose)),
              Slider(
                value:    selected.toDouble(),
                min:      21,
                max:      35,
                divisions: 14,
                activeColor: SakhiColors.rose,
                onChanged: (v) => setState(() => selected = v.round()),
              ),
              const Text('Most cycles are between 21 and 35 days',
                  style: TextStyle(fontSize: 12, color: SakhiColors.lgray),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                ref.read(cycleProvider.notifier).updateCycleLength(selected);
                Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  // ── Confirm reset dialog ──────────────────────────────────────────────────
  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset everything?'),
        content: const Text(
            'This will delete all your data including your journal entries, '
                'cycle history, and points. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await StorageService.clearAll();
              if (context.mounted) {
                Navigator.pop(context);
                ref.read(onboardingCompleteProvider.notifier).state = false;
                ref.read(userNameProvider.notifier).state = '';
              }
            },
            child: const Text('Yes, reset everything',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w700,
              color:      SakhiColors.lgray,
              letterSpacing: 0.8)),
    );
  }
}

// ── Test notification button ──────────────────────────────────────────────────
class _TestNotificationButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TestNotificationButton> createState() =>
      _TestNotificationButtonState();
}

class _TestNotificationButtonState
    extends ConsumerState<_TestNotificationButton> {
  bool _sending = false;

  Future<void> _sendTest() async {
    setState(() => _sending = true);
    try {
      final cycle    = ref.read(cycleProvider);
      final userName = ref.read(userNameProvider);
      final lastNote = StorageService.getLastJournalNote();

      // Generate a real Claude message
      final message = await BackgroundService.generateMorningMessage(
        userName:    userName,
        cycle:       cycle,
        lastJournal: lastNote,
      );

      // Fire immediately — no scheduling
      await NotificationService.showNow(
        id:    99,
        title: 'Good morning 🌸',
        body:  message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Test notification sent — check your notification bar'),
          backgroundColor: SakhiColors.sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not send — check your API key and internet'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: _sending ? null : _sendTest,
        style: OutlinedButton.styleFrom(
          foregroundColor:  SakhiColors.rose,
          side:             const BorderSide(color: SakhiColors.rose),
          padding:          const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape:            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          minimumSize:      const Size(double.infinity, 0),
        ),
        icon: _sending
            ? const SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: SakhiColors.rose))
            : const Icon(Icons.notifications_active_outlined, size: 18),
        label: Text(
            _sending ? 'Generating with Claude...' : 'Send test morning notification',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   value;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin:  const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:        SakhiColors.white,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: SakhiColors.petal),
        ),
        child: Row(
          children: [
            Icon(icon, color: SakhiColors.rose, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: SakhiColors.deep))),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: SakhiColors.lgray)),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: SakhiColors.lgray, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Evening journal demo button ───────────────────────────────────────────────
class _TestEveningButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TestEveningButton> createState() => _TestEveningButtonState();
}

class _TestEveningButtonState extends ConsumerState<_TestEveningButton> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await NotificationService.showNow(
        id:    98,
        title: 'Time to journal 📖',
        body:  'How did today go? Rate your tasks and jot down your thoughts — Sakhi will read it tonight.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Evening reminder sent — check your notification bar'),
          backgroundColor: SakhiColors.sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not send notification'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: _sending ? null : _send,
        style: OutlinedButton.styleFrom(
          foregroundColor: SakhiColors.amber,
          side:            const BorderSide(color: SakhiColors.amber),
          padding:         const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize:     const Size(double.infinity, 0),
        ),
        icon: _sending
            ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: SakhiColors.amber))
            : const Icon(Icons.book_outlined, size: 18),
        label: Text(
            _sending ? 'Sending...' : 'Send test evening journal reminder',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Pre-task briefing demo button ─────────────────────────────────────────────
class _TestPreTaskButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TestPreTaskButton> createState() => _TestPreTaskButtonState();
}

class _TestPreTaskButtonState extends ConsumerState<_TestPreTaskButton> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final cycle    = ref.read(cycleProvider);
      final tasks    = ref.read(tasksProvider);
      final userName = ref.read(userNameProvider);

      // Pick the next upcoming task or use a sample
      final now         = DateTime.now();
      final upcoming    = tasks.where((t) => t.time.isAfter(now)).toList();
      final taskTitle   = upcoming.isNotEmpty ? upcoming.first.title : 'Your next meeting';

      // Build phase-aware message
      final phaseMsg = _phaseMessage(cycle.phase.label);

      await NotificationService.showNow(
        id:    97,
        title: '$taskTitle in 30 minutes',
        body:  phaseMsg,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pre-task briefing sent for "$taskTitle"'),
          backgroundColor: SakhiColors.sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not send notification'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _phaseMessage(String phase) {
    switch (phase.toLowerCase()) {
      case 'menstrual':
        return 'Your energy may be lower today — focus on what matters most and give yourself grace for the rest.';
      case 'follicular':
        return 'Your mind is sharp and creative right now. Great time to bring new ideas to the table.';
      case 'ovulatory':
        return 'Peak communication phase — walk in with confidence. This is your strongest window for high-stakes conversations.';
      case 'luteal':
        return 'Detail and analysis are your strengths right now. Trust your instincts on the specifics.';
      default:
        return 'You\'ve got this. Show up as you are — that\'s always enough.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed: _sending ? null : _send,
        style: OutlinedButton.styleFrom(
          foregroundColor: SakhiColors.sage,
          side:            const BorderSide(color: SakhiColors.sage),
          padding:         const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize:     const Size(double.infinity, 0),
        ),
        icon: _sending
            ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: SakhiColors.sage))
            : const Icon(Icons.calendar_today_outlined, size: 18),
        label: Text(
            _sending ? 'Sending...' : 'Send test pre-task briefing',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}