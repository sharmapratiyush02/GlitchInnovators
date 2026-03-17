import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/sahara_theme.dart';
import '../models/models.dart';

// ── Crisis Banner ──────────────────────────────────────────────────────
class CrisisBanner extends StatelessWidget {
  const CrisisBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaharaTheme.crisisRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaharaTheme.crisisRed.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: SaharaTheme.crisisRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'You Are Not Alone',
                style: GoogleFonts.nunito(
                  color: SaharaTheme.crisisRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _HelplineRow(name: 'iCall', number: '9152987821'),
          const SizedBox(height: 4),
          _HelplineRow(
              name: 'Vandrevala Foundation', number: '1860-2662-345'),
        ],
      ),
    );
  }
}

class _HelplineRow extends StatelessWidget {
  final String name;
  final String number;
  const _HelplineRow({required this.name, required this.number});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name,
            style: GoogleFonts.nunito(
                fontSize: 13, fontWeight: FontWeight.w600)),
        Text(number,
            style: GoogleFonts.nunito(
                fontSize: 13,
                color: SaharaTheme.crisisRed,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Memory Card (inline in chat) ───────────────────────────────────────
class MemoryCard extends StatelessWidget {
  final Memory memory;
  const MemoryCard({super.key, required this.memory});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? SaharaTheme.darkCard
            : SaharaTheme.sandDeep,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SaharaTheme.ember.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: SaharaTheme.ember),
              const SizedBox(width: 6),
              Text(
                'Memory from ${memory.date}',
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: SaharaTheme.ember,
                ),
              ),
              const Spacer(),
              Text(
                '${memory.sender}',
                style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : SaharaTheme.mutedBrown),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            memory.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Mood Chip ──────────────────────────────────────────────────────────
class MoodChip extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  const MoodChip({
    super.key,
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Color(mood.color).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Color(mood.color)
                : Colors.grey.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              mood.label,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Color(mood.color)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Breathing Card ─────────────────────────────────────────────────────
class BreathingCard extends StatefulWidget {
  const BreathingCard({super.key});

  @override
  State<BreathingCard> createState() => _BreathingCardState();
}

class _BreathingCardState extends State<BreathingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SaharaTheme.sage.withOpacity(0.25),
            SaharaTheme.ember.withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (ctx, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SaharaTheme.sage.withOpacity(0.3),
                border: Border.all(
                    color: SaharaTheme.sage.withOpacity(0.6), width: 2),
              ),
              child: const Center(
                child: Icon(Icons.air, color: SaharaTheme.sage, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breathing Exercise',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Take a slow breath. Breathe in... breathe out.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading Dots ───────────────────────────────────────────────────────
class LoadingDots extends StatefulWidget {
  final Color? color;
  const LoadingDots({super.key, this.color});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? SaharaTheme.mutedBrown;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i / 3;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (ctx, _) {
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final opacity = (0.3 + 0.7 * (1 - (t * 2 - 1).abs())).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Safety Disclaimer ──────────────────────────────────────────────────
class SafetyDisclaimer extends StatelessWidget {
  const SafetyDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        '💛 Sahara uses only your saved memories. It is not a substitute for professional grief support.\n'
        'iCall: 9152987821 | Vandrevala: 1860-2662-345',
        style: GoogleFonts.nunito(
          fontSize: 11,
          color: SaharaTheme.mutedBrown,
          height: 1.5,
        ),
      ),
    );
  }
}
