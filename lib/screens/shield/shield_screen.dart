import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';

class ShieldScreen extends ConsumerStatefulWidget {
  const ShieldScreen({super.key});

  @override
  ConsumerState<ShieldScreen> createState() => _ShieldScreenState();
}

class _ShieldScreenState extends ConsumerState<ShieldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;
  bool _fakCallRinging = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggleShield() {
    HapticFeedback.heavyImpact();
    final shield = ref.read(shieldProvider);
    if (shield.isActive) {
      ref.read(shieldProvider.notifier).deactivate();
    } else {
      ref.read(shieldProvider.notifier).activate();
      _showActivatedSnack();
    }
  }

  void _showActivatedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Shield activated — recording started, location shared'),
        backgroundColor: SakhiColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _triggerFakeCall() {
    setState(() => _fakCallRinging = true);
    HapticFeedback.mediumImpact();
  }

  void _dismissFakeCall() {
    setState(() => _fakCallRinging = false);
  }

  @override
  Widget build(BuildContext context) {
    final shield = ref.watch(shieldProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(
        title: const Text('Sakhi Shield'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Status banner ──────────────────────────────────────────
                if (shield.isActive)
                  _StatusBanner(activatedAt: shield.activatedAt!),
                const SizedBox(height: 12),

                // ── Big shield button ──────────────────────────────────────
                _ShieldButton(
                  isActive: shield.isActive,
                  pulseAnim: _pulseAnim,
                  onToggle: _toggleShield,
                ),
                const SizedBox(height: 24),

                // ── How it works ───────────────────────────────────────────
                if (!shield.isActive) ...[
                  const _HowItWorks(),
                  const SizedBox(height: 16),
                ],

                // ── Emergency contacts ─────────────────────────────────────
                const SakhiSectionHeader(title: 'Emergency contacts'),
                const SizedBox(height: 10),
                _EmergencyContacts(contacts: shield.emergencyContacts),
                const SizedBox(height: 20),

                // ── Check-in timer ─────────────────────────────────────────
                _CheckInTimer(
                  minutes:   shield.checkInMinutes,
                  onChanged: (v) => ref.read(shieldProvider.notifier).setCheckIn(v),
                ),
                const SizedBox(height: 20),

                // ── Fake call ──────────────────────────────────────────────
                SakhiCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.call, color: SakhiColors.sage, size: 20),
                          SizedBox(width: 8),
                          Text('Fake call',
                            style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: SakhiColors.deep)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Makes your phone ring like you\'re getting a real call — '
                        'so you can act like you\'re on a call to exit a situation.',
                        style: TextStyle(fontSize: 13, color: SakhiColors.lgray, height: 1.5)),
                      const SizedBox(height: 14),
                      SakhiGradientButton(
                        label:  'Trigger fake call',
                        icon:   Icons.phone,
                        onTap:  _triggerFakeCall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // ── Fake call overlay ────────────────────────────────────────────
          if (_fakCallRinging)
            _FakeCallOverlay(onDismiss: _dismissFakeCall),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ShieldSettings(),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final DateTime activatedAt;
  const _StatusBanner({required this.activatedAt});

  @override
  Widget build(BuildContext context) {
    final mins = DateTime.now().difference(activatedAt).inMinutes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SakhiColors.sage.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SakhiColors.sage),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: SakhiColors.sage, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Shield is active',
                  style: TextStyle(
                    color: SakhiColors.sage, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('Recording • Location shared • Active for $mins min',
                  style: const TextStyle(color: SakhiColors.sage, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Big shield button ─────────────────────────────────────────────────────────
class _ShieldButton extends StatelessWidget {
  final bool isActive;
  final Animation<double> pulseAnim;
  final VoidCallback onToggle;

  const _ShieldButton({
    required this.isActive,
    required this.pulseAnim,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: isActive ? pulseAnim : const AlwaysStoppedAnimation(1.0),
          child: GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                  ? SakhiColors.sage
                  : SakhiColors.deep,
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? SakhiColors.sage : SakhiColors.rose).withOpacity(0.4),
                    blurRadius:   30,
                    spreadRadius: isActive ? 10 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive ? Icons.shield : Icons.shield_outlined,
                    color: Colors.white, size: 56),
                  const SizedBox(height: 8),
                  Text(
                    isActive ? 'ACTIVE' : 'ACTIVATE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13, fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isActive
            ? 'Tap to deactivate Shield'
            : 'Tap before you feel unsafe — not during',
          style: const TextStyle(fontSize: 13, color: SakhiColors.lgray),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('🛡️', 'Activate before you feel in danger — walking to your cab, leaving late from work'),
      ('📹', 'Camera and mic start recording silently with no visible change to your screen'),
      ('📍', 'Your live location is shared with your emergency contacts in real time'),
      ('☁️', 'Footage uploads immediately to encrypted cloud — safe even if your phone is taken'),
      ('⏱️', 'If you don\'t tap "I\'m safe" in time, contacts are automatically alerted'),
    ];

    return SakhiCard(
      color: SakhiColors.blush,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How Shield works',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.$2,
                    style: const TextStyle(fontSize: 13, color: SakhiColors.gray, height: 1.5)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Emergency contacts ────────────────────────────────────────────────────────
class _EmergencyContacts extends ConsumerWidget {
  final List<String> contacts;
  const _EmergencyContacts({required this.contacts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SakhiCard(
      child: Column(
        children: [
          if (contacts.isEmpty)
            const SakhiEmptyState(
              emoji: '👥',
              title: 'No contacts yet',
              subtitle: 'Add up to 3 emergency contacts'),
          ...contacts.map((c) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: SakhiColors.blush,
              child: Icon(Icons.person, color: SakhiColors.rose)),
            title: Text(c,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18, color: SakhiColors.lgray),
              onPressed: () => ref.read(shieldProvider.notifier).removeContact(c),
            ),
          )),
          if (contacts.length < 3)
            TextButton.icon(
              icon:  const Icon(Icons.add, color: SakhiColors.rose),
              label: const Text('Add contact', style: TextStyle(color: SakhiColors.rose)),
              onPressed: () => _showAddContact(context, ref),
            ),
        ],
      ),
    );
  }

  void _showAddContact(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add emergency contact'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Name or phone number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                ref.read(shieldProvider.notifier).addContact(ctrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Check-in timer ────────────────────────────────────────────────────────────
class _CheckInTimer extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _CheckInTimer({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [5, 10, 20, 30];
    return SakhiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Check-in timer',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 4),
          const Text('If you don\'t tap "I\'m safe" in time, your contacts are alerted automatically.',
            style: TextStyle(fontSize: 12, color: SakhiColors.lgray, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: options.map((m) {
              final selected = m == minutes;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onChanged(m),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? SakhiColors.rose : SakhiColors.blush,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? SakhiColors.rose : SakhiColors.petal),
                    ),
                    child: Text('${m}m',
                      style: TextStyle(
                        color:      selected ? Colors.white : SakhiColors.deep,
                        fontSize:   13,
                        fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Fake call overlay ─────────────────────────────────────────────────────────
class _FakeCallOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _FakeCallOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A20),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius:          50,
                    backgroundColor: SakhiColors.rose,
                    child:           Icon(Icons.person, color: Colors.white, size: 48)),
                  const SizedBox(height: 20),
                  const Text('Mum',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Incoming call...',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 16)),
                ],
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Decline
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 70, height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 30)),
                      ),
                      const SizedBox(height: 8),
                      Text('Decline',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 70, height: 70,
                          decoration: const BoxDecoration(
                            color: SakhiColors.sage, shape: BoxShape.circle),
                          child: const Icon(Icons.call, color: Colors.white, size: 30)),
                      ),
                      const SizedBox(height: 8),
                      Text('Accept',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shield settings ───────────────────────────────────────────────────────────
class _ShieldSettings extends StatelessWidget {
  const _ShieldSettings();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shield settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
          const SizedBox(height: 20),
          const Text('Recording quality'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: 'HD (recommended)',
            items: ['HD (recommended)', 'Standard', 'Audio only']
              .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value:    true,
            onChanged: (_) {},
            title: const Text('Share location continuously'),
            subtitle: const Text('While Shield is active'),
            activeColor: SakhiColors.rose,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value:    true,
            onChanged: (_) {},
            title: const Text('Auto-upload to cloud'),
            subtitle: const Text('Recordings saved even if phone is taken'),
            activeColor: SakhiColors.rose,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
