import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

// ── Section header ────────────────────────────────────────────────────────────
class SakhiSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SakhiSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!,
                style: const TextStyle(color: SakhiColors.rose, fontSize: 13)),
          ),
      ],
    );
  }
}

// ── Phase badge ───────────────────────────────────────────────────────────────
class PhaseBadge extends StatelessWidget {
  final CyclePhase phase;
  final bool large;

  const PhaseBadge({super.key, required this.phase, this.large = false});

  Color get bg {
    switch (phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrual;
      case CyclePhase.follicular: return SakhiColors.follicular;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatory;
      case CyclePhase.luteal:     return SakhiColors.luteal;
    }
  }

  Color get fg {
    switch (phase) {
      case CyclePhase.menstrual:  return SakhiColors.menstrualDark;
      case CyclePhase.follicular: return SakhiColors.follicularDark;
      case CyclePhase.ovulatory:  return SakhiColors.ovulatoryDark;
      case CyclePhase.luteal:     return SakhiColors.lutealDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical:   large ? 6  : 4,
      ),
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(phase.emoji, style: TextStyle(fontSize: large ? 14 : 11)),
          const SizedBox(width: 5),
          Text(
            phase.label,
            style: TextStyle(
              color:      fg,
              fontSize:   large ? 13 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sakhi card ────────────────────────────────────────────────────────────────
class SakhiCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const SakhiCard({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: padding ?? const EdgeInsets.all(14),
        margin:  const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        color ?? SakhiColors.white,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: SakhiColors.petal),
        ),
        child: child,
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────
class SakhiGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double? width;

  const SakhiGradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  width ?? double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SakhiColors.drose, SakhiColors.rose],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: SakhiColors.rose.withOpacity(0.3),
              blurRadius: 12, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: SakhiColors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(
              color: SakhiColors.white,
              fontSize: 15, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Star rating ───────────────────────────────────────────────────────────────
class StarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRating;

  const StarRating({super.key, this.initialRating = 0, required this.onRating});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () {
            setState(() => _rating = i + 1);
            widget.onRating(i + 1);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < _rating ? SakhiColors.gold : SakhiColors.lgray,
              size: 26,
            ),
          ),
        );
      }),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class SakhiEmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const SakhiEmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}