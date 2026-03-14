import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';

// ─────────────────────────────────────────────
// HUB CARD
// Large square card for the home screen 2×2 grid.
// Minimum height: 110px (EyerisTouchTargets.hubCard)
// ─────────────────────────────────────────────

class HubCard extends StatefulWidget {
  final String label;
  final String? sublabel;
  final Widget icon;
  final VoidCallback onTap;
  final String? badge;

  // Accessibility — always provide an explicit label
  final String semanticsLabel;
  final String? semanticsHint;

  const HubCard({
    super.key,
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onTap,
    this.badge,
    required this.semanticsLabel,
    this.semanticsHint,
  });

  @override
  State<HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<HubCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          constraints: const BoxConstraints(
            minHeight: EyerisTouchTargets.hubCard,
          ),
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFF1A1700) : EyerisColors.surface,
            border: Border.all(
              color: _pressed ? EyerisColors.borderFocus : EyerisColors.border,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Stack(
            children: [
              // Positioned.fill makes the Column fill the full card height,
              // so mainAxisAlignment.center actually centers content.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EyerisSpacing.sm,
                    vertical: EyerisSpacing.md,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon container
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: EyerisColors.black,
                          border: Border.all(
                            color: EyerisColors.primary,
                            width: EyerisBorders.thick,
                          ),
                          borderRadius: BorderRadius.circular(EyerisRadii.large),
                        ),
                        child: Center(child: widget.icon),
                      ),
                      const SizedBox(height: EyerisSpacing.sm),
                      // Card label
                      Text(
                        widget.label.toUpperCase(),
                        style: EyerisText.cardLabel,
                        textAlign: TextAlign.center,
                      ),
                      // Sublabel (optional)
                      if (widget.sublabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.sublabel!,
                          style: EyerisText.cardSub,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Badge (top-right corner)
              if (widget.badge != null)
                Positioned(
                  top: EyerisSpacing.sm,
                  right: EyerisSpacing.sm,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EyerisColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.badge!.toUpperCase(),
                        style: EyerisText.badge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// HUB CARD GRID
// 2-column grid layout with even gap.
// Accepts a fixed list of HubCard widgets.
// ─────────────────────────────────────────────

class HubCardGrid extends StatelessWidget {
  final List<HubCard> cards;
  final double gap;

  const HubCardGrid({
    super.key,
    required this.cards,
    this.gap = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    // Build rows of 2, each row Expanded so they share all available height.
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final left  = cards[i];
      final right = i + 1 < cards.length ? cards[i + 1] : null;

      rows.add(
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(
                child: right ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );

      if (i + 2 < cards.length) {
        rows.add(SizedBox(height: gap));
      }
    }

    // Must be in a parent that provides bounded height (e.g. Expanded in Column).
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
