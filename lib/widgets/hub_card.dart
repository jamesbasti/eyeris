// lib/widgets/hub_card.dart
// Large cards on the home screen. Min height 110px, border feedback on press.

import 'package:flutter/material.dart';

import 'package:eyeris/core/app_theme.dart';

/// Hub card: icon + label + sublabel + optional badge. Min height 110px.
/// Entire card is one touchable; pressed state changes border to primary (no opacity).
class HubCard extends StatefulWidget {
  const HubCard({
    super.key,
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onPress,
    this.badge,
    required this.accessibilityLabel,
    this.accessibilityHint,
    this.testID,
    this.enabled = true,
  });

  final String label;
  final String? sublabel;
  final Widget icon;
  final VoidCallback onPress;
  /// e.g. "AAA", "NEW", "LIVE"
  final String? badge;
  final String accessibilityLabel;
  final String? accessibilityHint;
  final String? testID;
  final bool enabled;

  @override
  State<HubCard> createState() => _HubCardState();
}

class _HubCardState extends State<HubCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? EyerisTheme.border
        : _pressed
            ? EyerisTheme.primary
            : EyerisTheme.border;

    return Semantics(
      label: widget.accessibilityLabel,
      hint: widget.accessibilityHint,
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPress : null,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.4,
          child: Container(
            constraints: BoxConstraints(minHeight: EyerisTheme.touchHubCard),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: EyerisTheme.surface,
              borderRadius: BorderRadius.circular(EyerisTheme.radiusLarge),
              border: Border.all(color: borderColor, width: EyerisTheme.borderThick),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Badge (optional), top-right, 8px from top and right
                if (widget.badge != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: EyerisTheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.badge!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontFamily: EyerisTheme.fontFamily,
                          letterSpacing: 0.05 * 7,
                        ),
                      ),
                    ),
                  ),
                // Column: icon, label, sublabel
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon container: 48×48, radius 12, background #000, border 2px primary
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: EyerisTheme.primary, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: widget.icon,
                      ),
                      const SizedBox(height: 8),
                      // Label: 11px bold white UPPERCASE, center, letter-spacing 0.08em, line-height 1.3
                      Text(
                        widget.label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: typography(
                          size: 'sm',
                          weight: FontWeight.w700,
                          color: EyerisTheme.textPrimary,
                          letterSpacingKey: 'wide',
                        ).copyWith(
                          height: 1.3,
                          letterSpacing: 11 * 0.08,
                        ),
                      ),
                      if (widget.sublabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.sublabel!,
                          textAlign: TextAlign.center,
                          style: typography(
                            size: 'xs',
                            color: EyerisTheme.textMuted,
                            letterSpacingKey: 'tight',
                          ).copyWith(
                            height: 1.4,
                            letterSpacing: 9 * 0.03,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-column grid for hub cards. Gap 10px; optional [fillLastRow] for odd count.
class HubCardGrid extends StatelessWidget {
  const HubCardGrid({
    super.key,
    this.children = const [],
    this.padding = const EdgeInsets.all(14),
    this.gap = 10,
    this.fillLastRow = false,
  });

  /// Direct list of [HubCard] (or other) widgets.
  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;
  /// When true and child count is odd, last card spans full width.
  final bool fillLastRow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = 2;
          final itemWidth = (constraints.maxWidth - gap) / crossAxisCount;
          final count = children.length;
          final isOdd = count.isOdd;
          final lastFullWidth = fillLastRow && isOdd;

          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (int i = 0; i < count; i++)
                SizedBox(
                  width: lastFullWidth && i == count - 1 ? constraints.maxWidth : itemWidth,
                  child: children[i],
                ),
            ],
          );
        },
      ),
    );
  }
}
