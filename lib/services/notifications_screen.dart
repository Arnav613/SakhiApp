import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakhi/models/models.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/background_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Morning check-in
  bool _morningEnabled  = true;
  int  _morningHour     = 7;
  int  _morningMinute   = 30;

  // Evening journal
  bool _eveningEnabled  = true;
  int  _eveningHour     = 21;
  int  _eveningMinute   = 0;

  // Pre-task briefings
  bool _preTaskEnabled  = true;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  void _loadSaved() {
    final box = StorageService.getNotificationSettings();
    setState(() {
      _morningEnabled  = box['morningEnabled']  as bool? ?? true;
      _morningHour     = box['morningHour']     as int?  ?? 7;
      _morningMinute   = box['morningMinute']   as int?  ?? 30;
      _eveningEnabled  = box['eveningEnabled']  as bool? ?? true;
      _eveningHour     = box['eveningHour']     as int?  ?? 21;
      _eveningMinute   = box['eveningMinute']   as int?  ?? 0;
      _preTaskEnabled  = box['preTaskEnabled']  as bool? ?? true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await StorageService.saveNotificationSettings({
        'morningEnabled':  _morningEnabled,
        'morningHour':     _morningHour,
        'morningMinute':   _morningMinute,
        'eveningEnabled':  _eveningEnabled,
        'eveningHour':     _eveningHour,
        'eveningMinute':   _eveningMinute,
        'preTaskEnabled':  _preTaskEnabled,
      });

      await NotificationService.cancelAll();

      final cycle    = ref.read(cycleProvider);
      final userName = ref.read(userNameProvider);

      if (_morningEnabled) {
        await BackgroundService.scheduleMorningTask(
          hour:   _morningHour,
          minute: _morningMinute,
        );
      } else {
        await BackgroundService.cancelMorningTask();
      }

      if (_eveningEnabled) {
        await NotificationService.scheduleEveningJournal(
          hour:   _eveningHour,
          minute: _eveningMinute,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Notifications saved'),
          backgroundColor: SakhiColors.sage,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      debugPrint('Save notifications error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Saved — some notifications may need app restart'),
          backgroundColor: SakhiColors.gold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } finally {
      // Always reset loading — no matter what happens
      if (mounted) setState(() => _saving = false);
    }
  }

  String _morningMessage(String name, String phase, int day) {
    return "Good morning $name! You're on day $day — $phase phase. Open Sakhi to see today's plan.";
  }

  String _formatTime(int hour, int minute) {
    final h   = hour % 12 == 0 ? 12 : hour % 12;
    final m   = minute.toString().padLeft(2, '0');
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Future<void> _pickTime({
    required bool isMorning,
    required int currentHour,
    required int currentMinute,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary:   SakhiColors.rose,
            onPrimary: Colors.white,
            surface:   SakhiColors.vblush,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningHour   = picked.hour;
          _morningMinute = picked.minute;
        } else {
          _eveningHour   = picked.hour;
          _eveningMinute = picked.minute;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Morning check-in ────────────────────────────────────
            _SectionLabel('Morning check-in'),
            _NotifCard(
              icon:     Icons.wb_sunny_outlined,
              iconColor: SakhiColors.gold,
              title:    'Daily morning check-in',
              subtitle: 'Sakhi greets you with your cycle phase and today\'s tasks',
              enabled:  _morningEnabled,
              onToggle: (v) => setState(() => _morningEnabled = v),
              trailing: _morningEnabled
                  ? _TimeChip(
                time:    _formatTime(_morningHour, _morningMinute),
                onTap:   () => _pickTime(
                  isMorning:     true,
                  currentHour:   _morningHour,
                  currentMinute: _morningMinute,
                ),
              )
                  : null,
            ),

            // ── Preview ─────────────────────────────────────────────
            if (_morningEnabled) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin:  const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color:        const Color(0xFF3B1040),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        SakhiColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Preview',
                          style: TextStyle(color: SakhiColors.gold, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _morningMessage(
                        ref.watch(userNameProvider),
                        ref.watch(cycleProvider).phase.label,
                        ref.watch(cycleProvider).dayOfCycle,
                      ),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            // ── Evening journal ─────────────────────────────────────
            _SectionLabel('Evening journal'),
            _NotifCard(
              icon:      Icons.book_outlined,
              iconColor: SakhiColors.rose,
              title:    'Journal reminder',
              subtitle: 'Reminds you to rate your day and write your thoughts',
              enabled:  _eveningEnabled,
              onToggle: (v) => setState(() => _eveningEnabled = v),
              trailing: _eveningEnabled
                  ? _TimeChip(
                time:  _formatTime(_eveningHour, _eveningMinute),
                onTap: () => _pickTime(
                  isMorning:     false,
                  currentHour:   _eveningHour,
                  currentMinute: _eveningMinute,
                ),
              )
                  : null,
            ),

            // ── Pre-task briefings ──────────────────────────────────
            _SectionLabel('Pre-task briefings'),
            _NotifCard(
              icon:      Icons.notifications_outlined,
              iconColor: SakhiColors.sage,
              title:    '30-min pre-task pep talk',
              subtitle: 'Phase-aware briefing before each calendar event',
              enabled:  _preTaskEnabled,
              onToggle: (v) => setState(() => _preTaskEnabled = v),
            ),

            const SizedBox(height: 24),

            // ── Save button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SakhiColors.rose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Save notifications',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize:      12,
              fontWeight:    FontWeight.w700,
              color:         SakhiColors.lgray,
              letterSpacing: 0.8)),
    );
  }
}

// ── Notification card ─────────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final IconData  icon;
  final Color     iconColor;
  final String    title;
  final String    subtitle;
  final bool      enabled;
  final ValueChanged<bool> onToggle;
  final Widget?   trailing;

  const _NotifCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        SakhiColors.white,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: SakhiColors.petal),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color:        iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: SakhiColors.deep)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: SakhiColors.lgray, height: 1.4)),
                  ],
                ),
              ),
              Switch(
                value:           enabled,
                onChanged:       onToggle,
                activeColor:     SakhiColors.rose,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: SakhiColors.petal),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Scheduled time',
                    style: TextStyle(fontSize: 13, color: SakhiColors.lgray)),
                const Spacer(),
                trailing!,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Time chip ─────────────────────────────────────────────────────────────────
class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;
  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:        SakhiColors.blush,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: SakhiColors.rose),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time,
                style: const TextStyle(
                    color: SakhiColors.rose, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 5),
            const Icon(Icons.edit, color: SakhiColors.rose, size: 12),
          ],
        ),
      ),
    );
  }
}