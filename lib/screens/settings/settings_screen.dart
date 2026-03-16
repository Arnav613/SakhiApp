import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../services/storage_service.dart';

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

// ── Settings tile ─────────────────────────────────────────────────────────────
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
            Text(value,
                style: const TextStyle(fontSize: 13, color: SakhiColors.lgray)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: SakhiColors.lgray, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}