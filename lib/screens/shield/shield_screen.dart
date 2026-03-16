import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/shield_service.dart';

class ShieldScreen extends ConsumerStatefulWidget {
  const ShieldScreen({super.key});
  @override
  ConsumerState<ShieldScreen> createState() => _ShieldScreenState();
}

class _ShieldScreenState extends ConsumerState<ShieldScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;

  bool     _fakeCallRinging    = false;
  Timer?   _countdownTimer;
  int      _secondsRemaining   = 0;
  bool     _timerRunning       = false;
  bool     _sendingAlert       = false;
  Position? _lastPosition;
  StreamSubscription<Position>? _locationSub;
  bool     _recordingStarted   = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    // Request all permissions on screen load
    _requestPermissions();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownTimer?.cancel();
    _locationSub?.cancel();
    FlutterRingtonePlayer().stop();
    if (ShieldService.isRecording) ShieldService.stopRecording();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await ShieldService.requestAllPermissions();
  }

  // ── Activate shield ────────────────────────────────────────────────────────
  Future<void> _activateShield() async {
    HapticFeedback.heavyImpact();
    final shield = ref.read(shieldProvider);
    ref.read(shieldProvider.notifier).activate();

    // Start GPS tracking
    _startLocationTracking();

    // Start recording
    final recordingStarted = await ShieldService.startRecording();
    setState(() => _recordingStarted = recordingStarted);

    // Start countdown
    _startCountdown(shield.checkInMinutes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Shield active — GPS ${_lastPosition != null ? "tracking" : "acquiring"}'
                '${recordingStarted ? ", recording" : ""}'),
        backgroundColor: SakhiColors.sage,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Deactivate shield ──────────────────────────────────────────────────────
  Future<void> _deactivateShield() async {
    HapticFeedback.heavyImpact();
    ref.read(shieldProvider.notifier).deactivate();
    _stopCountdown();
    _locationSub?.cancel();

    // Stop recording and show where it was saved
    final path = await ShieldService.stopRecording();
    if (mounted && path != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Recording saved to app storage'),
        backgroundColor: SakhiColors.deep,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: SakhiColors.gold,
          onPressed: () {},
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _toggleShield() {
    final shield = ref.read(shieldProvider);
    if (shield.isActive) {
      _deactivateShield();
    } else {
      _activateShield();
    }
  }

  // ── Location tracking ──────────────────────────────────────────────────────
  void _startLocationTracking() {
    _locationSub?.cancel();
    _locationSub = ShieldService.getLiveLocationStream().listen(
          (position) => setState(() => _lastPosition = position),
      onError: (e) => debugPrint('Location stream error: $e'),
    );
    // Also get immediate fix
    ShieldService.getCurrentLocation().then((pos) {
      if (pos != null && mounted) setState(() => _lastPosition = pos);
    });
  }

  // ── Countdown timer ────────────────────────────────────────────────────────
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
          // Timer expired — send alert automatically, no popup
          _sendAlertAutomatically();
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() { _timerRunning = false; _secondsRemaining = 0; });
  }

  // ── Auto-send when timer expires ───────────────────────────────────────────
  Future<void> _sendAlertAutomatically() async {
    HapticFeedback.heavyImpact();
    final contacts = ref.read(shieldProvider).emergencyContacts;

    // Send immediately with no popup
    await _doSendAlert('Check-in timer expired. I may need help. Last known location:');

    // Restart timer
    final shield = ref.read(shieldProvider);
    if (shield.isActive && mounted) {
      _startCountdown(shield.checkInMinutes);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(contacts.isEmpty
            ? 'Timer expired — add emergency contacts to send alerts'
            : 'Alert sent to ${contacts.length} contact${contacts.length > 1 ? "s" : ""} — timer restarted'),
        backgroundColor: contacts.isEmpty ? Colors.orange : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Manual "I am not safe" button ─────────────────────────────────────────
  Future<void> _onNotSafePressed() async {
    HapticFeedback.heavyImpact();
    // Send immediately — no confirmation dialog, no delay
    await _doSendAlert('I pressed the emergency button. I need help. My location:');
  }

  // ── Core send logic ────────────────────────────────────────────────────────
  Future<void> _doSendAlert(String reason) async {
    if (_sendingAlert) return;
    setState(() => _sendingAlert = true);

    final contacts = ref.read(shieldProvider).emergencyContacts;
    await ShieldService.sendEmergencySms(contacts: contacts, reason: reason);

    if (mounted) setState(() => _sendingAlert = false);
  }

  // ── Fake call ──────────────────────────────────────────────────────────────
  void _triggerFakeCall() {
    setState(() => _fakeCallRinging = true);
    HapticFeedback.mediumImpact();
    FlutterRingtonePlayer().playRingtone(looping: true, volume: 1.0);
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
      appBar: AppBar(
        title: const Text('Sakhi Shield'),
        actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _showSettings(context))],
      ),
      body: Stack(children: [
        // Invisible camera preview — needed for recording to work on some devices
        if (ShieldService.cameraController != null &&
            ShieldService.cameraController!.value.isInitialized)
          Positioned(
            left: -1, top: -1,
            width: 1,  height: 1,
            child: CameraPreview(ShieldService.cameraController!),
          ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [

            // Status banner
            if (shield.isActive) _StatusBanner(
              activatedAt:    shield.activatedAt!,
              position:       _lastPosition,
              isRecording:    _recordingStarted,
            ),
            const SizedBox(height: 12),

            // Shield button
            _ShieldButton(isActive: shield.isActive, pulseAnim: _pulseAnim, onToggle: _toggleShield),
            const SizedBox(height: 16),

            // NOT SAFE button — no popup, sends immediately
            if (shield.isActive)
              _NotSafeButton(sending: _sendingAlert, onPressed: _onNotSafePressed),

            const SizedBox(height: 8),

            // Countdown
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
              _CheckInTimer(
                minutes:   shield.checkInMinutes,
                onChanged: (v) => ref.read(shieldProvider.notifier).setCheckIn(v),
              ),
            const SizedBox(height: 20),

            // Fake call card
            SakhiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.call, color: SakhiColors.sage, size: 20),
                SizedBox(width: 8),
                Text('Fake call', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
              ]),
              const SizedBox(height: 6),
              const Text("Makes your phone ring like a real call so you can safely exit a situation.", style: TextStyle(fontSize: 13, color: SakhiColors.lgray, height: 1.5)),
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

// ── Not safe button ───────────────────────────────────────────────────────────
class _NotSafeButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onPressed;
  const _NotSafeButton({required this.sending, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: sending ? null : onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: sending ? Colors.red.shade300 : Colors.red,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (sending)
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          else
            const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Text(
            sending ? 'SENDING ALERT...' : 'I AM NOT SAFE — SEND ALERT',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ]),
      ),
    );
  }
}

// ── Status banner with GPS ────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final DateTime  activatedAt;
  final Position? position;
  final bool      isRecording;
  const _StatusBanner({required this.activatedAt, this.position, required this.isRecording});

  @override
  Widget build(BuildContext context) {
    final mins    = DateTime.now().difference(activatedAt).inMinutes;
    final hasGps  = position != null;
    final lat     = position?.latitude.toStringAsFixed(4) ?? '...';
    final lng     = position?.longitude.toStringAsFixed(4) ?? '...';

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SakhiColors.sage.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: SakhiColors.sage)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield, color: SakhiColors.sage, size: 18),
          const SizedBox(width: 8),
          const Text('Shield is active', style: TextStyle(color: SakhiColors.sage, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('${mins}m', style: const TextStyle(color: SakhiColors.sage, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        // GPS status
        Row(children: [
          Icon(hasGps ? Icons.location_on : Icons.location_searching,
              color: hasGps ? SakhiColors.sage : SakhiColors.gold, size: 14),
          const SizedBox(width: 5),
          Text(
              hasGps ? 'GPS: $lat, $lng' : 'Acquiring GPS...',
              style: TextStyle(color: hasGps ? SakhiColors.sage : SakhiColors.gold, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        // Recording status
        Row(children: [
          Icon(isRecording ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
              color: isRecording ? Colors.red : SakhiColors.lgray, size: 14),
          const SizedBox(width: 5),
          Text(
              isRecording ? 'Recording video + audio' : 'Recording unavailable',
              style: TextStyle(color: isRecording ? Colors.red : SakhiColors.lgray, fontSize: 11)),
        ]),
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
              Text(isActive ? 'ACTIVE' : 'ACTIVATE',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
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
        const Text("Tap before 00:00 — alert sends automatically when timer expires.", style: TextStyle(fontSize: 11, color: SakhiColors.lgray), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  const _HowItWorks();
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('🛡️', 'Activate before you feel unsafe — the app starts GPS tracking and recording immediately'),
      ('📹', 'Video and audio recording starts silently and saves to your device'),
      ('📍', 'Your live GPS coordinates are tracked and included in every alert message'),
      ('⏱️', 'If the timer hits zero, an SMS with your location is sent automatically — no button needed'),
      ('🆘', 'Tap "I am not safe" at any time to send an immediate SMS alert with your location'),
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
        const SakhiEmptyState(emoji: '👥', title: 'No contacts yet', subtitle: 'Add up to 3 phone numbers'),
      ...contacts.map((c) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(backgroundColor: SakhiColors.blush, child: Icon(Icons.person, color: SakhiColors.rose)),
        title: Text(c, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: IconButton(icon: const Icon(Icons.close, size: 18, color: SakhiColors.lgray), onPressed: () => ref.read(shieldProvider.notifier).removeContact(c)),
      )),
      if (contacts.length < 3)
        TextButton.icon(icon: const Icon(Icons.add, color: SakhiColors.rose), label: const Text('Add phone number', style: TextStyle(color: SakhiColors.rose)), onPressed: () => _showAdd(context, ref)),
    ]));
  }
  void _showAdd(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Add emergency contact'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: ctrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: '+91 98765 43210', labelText: 'Phone number')),
        const SizedBox(height: 8),
        const Text('Enter the phone number including country code. Alerts will be sent as SMS directly to this number.', style: TextStyle(fontSize: 11, color: SakhiColors.lgray, height: 1.5)),
      ]),
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
    final options = [15, 30, 45, 60];
    return SakhiCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Check-in timer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SakhiColors.deep)),
      const SizedBox(height: 4),
      const Text("SMS alert sends automatically when timer hits zero — no button needed.", style: TextStyle(fontSize: 12, color: SakhiColors.lgray, height: 1.5)),
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
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Share location in alerts'), subtitle: const Text('GPS coordinates included in every SMS'), activeColor: SakhiColors.rose),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Auto-send on timer expiry'), subtitle: const Text('No confirmation needed'), activeColor: SakhiColors.rose),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: true, onChanged: (_) {}, title: const Text('Record video + audio'), subtitle: const Text('Saved to device storage'), activeColor: SakhiColors.rose),
        const SizedBox(height: 16),
      ]),
    );
  }
}