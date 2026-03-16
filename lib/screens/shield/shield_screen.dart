import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
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
  bool  _fakeCallRinging = false;
  Timer? _countdownTimer;
  int    _secondsRemaining = 0;
  bool   _timerRunning     = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    FlutterRingtonePlayer().stop();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startCountdown(int minutes) {
    _countdownTimer?.cancel();
    setState(() { _secondsRemaining = minutes * 60; _timerRunning = true; });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timerRunning = false;
          timer.cancel();
          _triggerAlert(autoTriggered: true);
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() { _timerRunning = false; _secondsRemaining = 0; });
  }

  // ── Send SMS alert to all contacts ────────────────────────────────────────
  Future<void> _sendSmsAlert({required String reason}) async {
    final contacts = ref.read(shieldProvider).emergencyContacts;

    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No emergency contacts added — go to Shield and add contacts first'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final message = Uri.encodeComponent(
        'SAKHI ALERT: $reason\n'
            'This is an automated safety alert from the Sakhi app.\n'
            'Please check on me immediately.'
    );

    // Send to each contact one by one
    for (final contact in contacts) {
      // Strip spaces from phone numbers
      final number = contact.replaceAll(' ', '');
      final uri    = Uri.parse('sms:$number?body=$message');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // Small delay between opening SMS for each contact
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  // ── Alert dialogs ─────────────────────────────────────────────────────────
  void _triggerAlert({bool autoTriggered = false}) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        title: const Row(children: [
          Icon(Icons.warning_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Alert triggered!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ]),
        content: Text(
            autoTriggered
                ? 'Your check-in timer expired. Send an alert to your emergency contacts now?'
                : 'Send an emergency alert to your contacts?',
            style: const TextStyle(height: 1.5)),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await _sendSmsAlert(reason: autoTriggered
                  ? 'Check-in timer expired. I may need help.'
                  : 'I pressed the emergency button. I need help.');
              final shield = ref.read(shieldProvider);
              if (shield.isActive) _startCountdown(shield.checkInMinutes);
            },
            child: const Text("Send alert now", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (autoTriggered) {
                final shield = ref.read(shieldProvider);
                if (shield.isActive) _startCountdown(shield.checkInMinutes);
              }
            },
            child: const Text("I'm safe — dismiss"),
          ),
        ],
      ),
    );
  }

  // ── Toggle shield ─────────────────────────────────────────────────────────
  void _toggleShield() {
    HapticFeedback.heavyImpact();
    final shield = ref.read(shieldProvider);
    if (shield.isActive) {
      ref.read(shieldProvider.notifier).deactivate();
      _stopCountdown();
    } else {
      ref.read(shieldProvider.notifier).activate();
      _startCountdown(shield.checkInMinutes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Shield activated — timer set for ${shield.checkInMinutes} minutes'),
        backgroundColor: SakhiColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Fake call with ringtone ───────────────────────────────────────────────
  void _triggerFakeCall() {
    setState(() => _fakeCallRinging = true);
    HapticFeedback.mediumImpact();
    // Play system ringtone
    FlutterRingtonePlayer().playRingtone(
      looping: true,
      volume:  1.0,
    );
  }

  void _dismissFakeCall() {
    FlutterRingtonePlayer().stop();
    setState(() => _fakeCallRinging = false);
  }

  String get _timerDisplay {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining  % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final shield = ref.watch(shieldProvider);
    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('Sakhi Shield'), actions: [
        IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _showSettings(context)),
      ]),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (shield.isActive) _StatusBanner(activatedAt: shield.activatedAt!),
            const SizedBox(height: 12),

            _ShieldButton(isActive: shield.isActive, pulseAnim: _pulseAnim, onToggle: _toggleShield),
            const SizedBox(height: 16),

            // ── I AM NOT SAFE button — always visible when shield is active ──
            if (shield.isActive)
              _NotSafeButton(onPressed: () => _triggerAlert(autoTriggered: false)),

            const SizedBox(height: 8),

            if (shield.isActive && _timerRunning)
              _CountdownCard(
                display:   _timerDisplay,
                seconds:   _secondsRemaining,
                totalSecs: shield.checkInMinutes * 60,
                onImSafe:  () {
                  HapticFeedback.mediumImpact();
                  _stopCountdown();
                  _startCountdown(shield.checkInMinutes);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Check-in confirmed — timer restarted'),
                    backgroundColor: SakhiColors.sage,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
              ),

            const SizedBox(height: 8),
            if (!shield.isActive) ...[const _HowItWorks(), const SizedBox(height: 16)],

            const SakhiSectionHeader(title: 'Emergency contacts'),
            const SizedBox(height: 10),
            _EmergencyContacts(contacts: shield.emergencyContacts),
            const SizedBox(height: 20),

            if (!shield.isActive)
              _CheckInTimer(minutes: shield.checkInMinutes, onChanged: (v) => ref.read(shieldProvider.notifier).setCheckIn(v)),
            const SizedBox(height: 20),

            // ── Fake call card ─────────────────────────────────────────────
            SakhiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.call, color: SakhiColors.sage, size: 20),
                SizedBox(width: 8),
                Text('Fake call', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
              ]),
              const SizedBox(height: 6),
              const Text("Makes your phone ring like a real incoming call so you can safely exit a situation.", style: TextStyle(fontSize: 13, color: SakhiColors.lgray, height: 1.5)),
              const SizedBox(height: 14),
              SakhiGradientButton(label: 'Trigger fake call', icon: Icons.phone, onTap: _triggerFakeCall),
            ])),
            const SizedBox(height: 80),
          ]),
        ),
        if (_fakeCallRinging) _FakeCallOverlay(onDismiss: _dismissFakeCall),
      ]),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ShieldSettings(),
    );
  }
}

// ── I am not safe button ──────────────────────────────────────────────────────
class _NotSafeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _NotSafeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin:  const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color:        Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:       Colors.red.withOpacity(0.4),
              blurRadius:  20,
              spreadRadius: 2,
              offset:      const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'I AM NOT SAFE — SEND ALERT',
              style: TextStyle(
                color:         Colors.white,
                fontSize:      15,
                fontWeight:    FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Countdown card ────────────────────────────────────────────────────────────
class _CountdownCard extends StatelessWidget {
  final String display;
  final int seconds, totalSecs;
  final VoidCallback onImSafe;
  const _CountdownCard({required this.display, required this.seconds, required this.totalSecs, required this.onImSafe});

  Color get _color {
    final p = totalSecs > 0 ? seconds / totalSecs : 0.0;
    if (p > 0.5) return SakhiColors.sage;
    if (p > 0.2) return SakhiColors.gold;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progress = totalSecs > 0 ? seconds / totalSecs : 0.0;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: SakhiColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _color, width: 1.5)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Check-in timer', style: TextStyle(fontSize: 12, color: SakhiColors.lgray, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(display, style: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: _color)),
          ]),
          SizedBox(width: 64, height: 64, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: progress, strokeWidth: 6, backgroundColor: SakhiColors.petal, valueColor: AlwaysStoppedAnimation(_color)),
            Icon(Icons.shield, color: _color, size: 24),
          ])),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: SakhiColors.sage, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: onImSafe,
          child: const Text("I'm safe — reset timer", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        )),
        const SizedBox(height: 8),
        const Text("Tap before 00:00 to confirm you're safe.", style: TextStyle(fontSize: 11, color: SakhiColors.lgray), textAlign: TextAlign.center),
      ]),
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
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SakhiColors.sage.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: SakhiColors.sage)),
      child: Row(children: [
        const Icon(Icons.shield, color: SakhiColors.sage, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shield is active', style: TextStyle(color: SakhiColors.sage, fontWeight: FontWeight.w700, fontSize: 14)),
          Text('Active for $mins min', style: const TextStyle(color: SakhiColors.sage, fontSize: 11)),
        ])),
      ]),
    );
  }
}

// ── Shield button ─────────────────────────────────────────────────────────────
class _ShieldButton extends StatelessWidget {
  final bool isActive;
  final Animation<double> pulseAnim;
  final VoidCallback onToggle;
  const _ShieldButton({required this.isActive, required this.pulseAnim, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ScaleTransition(
        scale: isActive ? pulseAnim : const AlwaysStoppedAnimation(1.0),
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? SakhiColors.sage : SakhiColors.deep,
              boxShadow: [BoxShadow(color: (isActive ? SakhiColors.sage : SakhiColors.rose).withOpacity(0.4), blurRadius: 30, spreadRadius: isActive ? 10 : 0)],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isActive ? Icons.shield : Icons.shield_outlined, color: Colors.white, size: 56),
              const SizedBox(height: 8),
              Text(isActive ? 'ACTIVE' : 'ACTIVATE', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(isActive ? 'Tap to deactivate Shield' : 'Activate before you feel unsafe — not during',
          style: const TextStyle(fontSize: 13, color: SakhiColors.lgray), textAlign: TextAlign.center),
    ]);
  }
}

// ── How it works ──────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('🛡️', 'Activate before you feel unsafe — walking to your cab, leaving late from work'),
      ('📹', 'Camera and mic start recording silently with no visible change to your screen'),
      ('📍', 'Your live location is shared with your emergency contacts in real time'),
      ('☁️', 'Footage uploads immediately to encrypted cloud — safe even if your phone is taken'),
      ('⏱️', 'If you don\'t tap "I\'m safe" in time, contacts are automatically alerted'),
    ];
    return SakhiCard(
      color: SakhiColors.blush,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How Shield works', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
        const SizedBox(height: 12),
        ...steps.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.$1, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(s.$2, style: const TextStyle(fontSize: 13, color: SakhiColors.gray, height: 1.5))),
          ]),
        )),
      ]),
    );
  }
}

// ── Emergency contacts ────────────────────────────────────────────────────────
class _EmergencyContacts extends ConsumerWidget {
  final List<String> contacts;
  const _EmergencyContacts({required this.contacts});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SakhiCard(child: Column(children: [
      if (contacts.isEmpty)
        const SakhiEmptyState(emoji: '👥', title: 'No contacts yet', subtitle: 'Add up to 3 emergency contacts'),
      ...contacts.map((c) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(backgroundColor: SakhiColors.blush, child: Icon(Icons.person, color: SakhiColors.rose)),
        title: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: IconButton(icon: const Icon(Icons.close, size: 18, color: SakhiColors.lgray), onPressed: () => ref.read(shieldProvider.notifier).removeContact(c)),
      )),
      if (contacts.length < 3)
        TextButton.icon(icon: const Icon(Icons.add, color: SakhiColors.rose), label: const Text('Add contact', style: TextStyle(color: SakhiColors.rose)), onPressed: () => _showAdd(context, ref)),
    ]));
  }
  void _showAdd(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add emergency contact'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'Phone number (e.g. +91 98765 43210)')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { if (ctrl.text.isNotEmpty) { ref.read(shieldProvider.notifier).addContact(ctrl.text); Navigator.pop(context); } }, child: const Text('Add')),
      ],
    ));
  }
}

// ── Check-in timer selector ───────────────────────────────────────────────────
class _CheckInTimer extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  const _CheckInTimer({required this.minutes, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final options = [10, 15, 30, 45];
    return SakhiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Check-in timer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
      const SizedBox(height: 4),
      const Text("If you don't tap \"I'm safe\" before the timer hits zero, your contacts are alerted.", style: TextStyle(fontSize: 12, color: SakhiColors.lgray, height: 1.5)),
      const SizedBox(height: 12),
      Row(children: options.map((m) {
        final selected = m == minutes;
        return Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
          onTap: () => onChanged(m),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: selected ? SakhiColors.rose : SakhiColors.blush, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? SakhiColors.rose : SakhiColors.petal)),
            child: Text('${m}m', style: TextStyle(color: selected ? Colors.white : SakhiColors.deep, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ));
      }).toList()),
    ]));
  }
}

// ── Fake call overlay ─────────────────────────────────────────────────────────
class _FakeCallOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  const _FakeCallOverlay({required this.onDismiss});
  @override
  State<_FakeCallOverlay> createState() => _FakeCallOverlayState();
}

class _FakeCallOverlayState extends State<_FakeCallOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A0A20),
      child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Padding(padding: const EdgeInsets.all(32), child: Column(children: [
          const SizedBox(height: 40),
          ScaleTransition(scale: _anim, child: const CircleAvatar(radius: 56, backgroundColor: SakhiColors.rose, child: Icon(Icons.person, color: Colors.white, size: 52))),
          const SizedBox(height: 24),
          const Text('Mum', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Incoming call...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16)),
        ])),
        Padding(padding: const EdgeInsets.fromLTRB(48, 0, 48, 56), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _CallBtn(icon: Icons.call_end, color: Colors.red,       label: 'Decline', onTap: widget.onDismiss),
          _CallBtn(icon: Icons.call,     color: SakhiColors.sage, label: 'Accept',  onTap: widget.onDismiss),
        ])),
      ])),
    );
  }
}

class _CallBtn extends StatelessWidget {
  final IconData icon; final Color color; final String label; final VoidCallback onTap;
  const _CallBtn({required this.icon, required this.color, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(onTap: onTap, child: Container(width: 72, height: 72, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 32))),
      const SizedBox(height: 10),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
    ]);
  }
}

// ── Shield settings ───────────────────────────────────────────────────────────
class _ShieldSettings extends StatelessWidget {
  const _ShieldSettings();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Shield settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
        const SizedBox(height: 20),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Share location continuously'), subtitle: const Text('While Shield is active'), activeColor: SakhiColors.rose),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Auto-upload to cloud'), subtitle: const Text('Recordings saved even if phone is taken'), activeColor: SakhiColors.rose),
        const SizedBox(height: 16),
      ]),
    );
  }
}