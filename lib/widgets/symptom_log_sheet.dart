import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/cycle_health_service.dart';
import '../../services/storage_service.dart';

class SymptomLogSheet extends StatefulWidget {
  final DateTime periodStartDate;
  final int? previousCycleLength;
  final VoidCallback onSaved;

  const SymptomLogSheet({
    super.key,
    required this.periodStartDate,
    this.previousCycleLength,
    required this.onSaved,
  });

  @override
  State<SymptomLogSheet> createState() => _SymptomLogSheetState();
}

class _SymptomLogSheetState extends State<SymptomLogSheet> {
  int       _painLevel  = 0;
  FlowLevel? _flowLevel;
  bool      _missed     = false;
  bool      _saving     = false;

  Future<void> _save() async {
    setState(() => _saving = true);

    final record = CycleRecord(
      startDate:    widget.periodStartDate,
      cycleLength:  widget.previousCycleLength,
      painLevel:    _painLevel > 0 ? _painLevel : null,
      flowLevel:    _flowLevel,
      periodMissed: _missed ? true : null,
    );

    await StorageService.saveCycleRecord(record.toMap());

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: SakhiColors.petal,
                borderRadius: BorderRadius.circular(2)),
          )),

          const Text('Log your symptoms',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: SakhiColors.deep)),
          const SizedBox(height: 4),
          const Text(
              'This helps Sakhi detect patterns and flag anything worth discussing with your doctor.',
              style: TextStyle(fontSize: 12, color: SakhiColors.lgray, height: 1.5)),
          const SizedBox(height: 20),

          // Missed period toggle
          _SectionLabel('Did your period come as expected?'),
          Row(children: [
            _OptionChip(
              label: 'Yes, it came',
              selected: !_missed,
              onTap: () => setState(() => _missed = false),
              color: SakhiColors.sage,
            ),
            const SizedBox(width: 8),
            _OptionChip(
              label: 'No, it was missed',
              selected: _missed,
              onTap: () => setState(() => _missed = true),
              color: SakhiColors.menstrualDark,
            ),
          ]),
          const SizedBox(height: 18),

          // Pain level
          _SectionLabel('Pain level (1 = mild, 5 = severe)'),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final level = i + 1;
              final selected = _painLevel == level;
              return GestureDetector(
                onTap: () => setState(() => _painLevel = level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color:        selected ? SakhiColors.menstrualDark : SakhiColors.blush,
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(
                        color: selected
                            ? SakhiColors.menstrualDark
                            : SakhiColors.petal),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          level <= 2 ? '😌' : level == 3 ? '😐' : level == 4 ? '😣' : '😰',
                          style: const TextStyle(fontSize: 18)),
                      Text('$level',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : SakhiColors.lgray)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),

          // Flow level
          _SectionLabel('Flow heaviness'),
          Wrap(
            spacing: 8,
            children: FlowLevel.values.map((f) => _OptionChip(
              label: '${f.emoji} ${f.label}',
              selected: _flowLevel == f,
              onTap: () => setState(() => _flowLevel = f),
              color: SakhiColors.menstrualDark,
            )).toList(),
          ),
          const SizedBox(height: 24),

          // Save
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: SakhiColors.menstrualDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Save symptoms',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onSaved();
            },
            child: const Center(
                child: Text('Skip for now',
                    style: TextStyle(color: SakhiColors.lgray, fontSize: 13))),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: SakhiColors.deep)),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        selected ? color : SakhiColors.blush,
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(
              color: selected ? color : SakhiColors.petal),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : SakhiColors.gray)),
      ),
    );
  }
}