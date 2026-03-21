import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/cycle_health_service.dart';
import '../../services/storage_service.dart';

class HealthAlertsSection extends StatelessWidget {
  const HealthAlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final records = StorageService.getCycleRecords()
        .map((m) => CycleRecord.fromMap(m))
        .toList();

    if (!CycleHealthService.hasEnoughData(records)) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        SakhiColors.vblush,
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: SakhiColors.petal),
        ),
        child: Row(children: [
          const Text('🩺', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(
              'Log 2+ cycles to unlock health pattern detection',
              style: const TextStyle(fontSize: 13, color: SakhiColors.lgray))),
        ]),
      );
    }

    final alerts = CycleHealthService.analyse(records);

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        const Color(0xFFEAF4F1),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: SakhiColors.sage.withOpacity(0.4)),
        ),
        child: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text(
              'No pattern concerns detected across your recent cycles. Keep logging!',
              style: const TextStyle(fontSize: 13, color: SakhiColors.gray))),
        ]),
      );
    }

    return Column(
      children: alerts.map((alert) => _AlertCard(alert: alert)).toList(),
    );
  }
}

// ── Alert card ────────────────────────────────────────────────────────────────
class _AlertCard extends StatefulWidget {
  final HealthAlert alert;
  const _AlertCard({required this.alert});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.alert;
    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        a.bgColor,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: a.color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Header — always visible
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w700, color: a.color)),
                        const SizedBox(height: 2),
                        Text(a.condition,
                            style: TextStyle(fontSize: 11,
                                color: a.color.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: a.color, size: 20),
                ],
              ),
            ),
          ),

          // Expanded content
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(a.body,
                      style: const TextStyle(fontSize: 13, color: SakhiColors.gray, height: 1.6)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: a.color, size: 15),
                        const SizedBox(width: 7),
                        Expanded(child: Text(a.suggestion,
                            style: TextStyle(fontSize: 12, color: a.color,
                                fontWeight: FontWeight.w500, height: 1.5))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                      'This is not a diagnosis. Sakhi flags patterns to help you have '
                          'more informed conversations with your doctor.',
                      style: TextStyle(fontSize: 10, color: SakhiColors.lgray,
                          fontStyle: FontStyle.italic, height: 1.5)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}