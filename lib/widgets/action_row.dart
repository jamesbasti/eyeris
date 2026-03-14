import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eyeris/core/app_theme.dart';

// ─────────────────────────────────────────────
// ACTION ROW
// Primary list-item component used on every sub-screen.
//
// Spec:
//   Height  : min 80px (EyerisTouchTargets.actionRow)
//   Bg      : EyerisColors.surface (#161616)
//   Border  : 2.5px EyerisColors.border, pressed → EyerisColors.borderFocus
//   Radius  : EyerisRadii.card (16px)
//   Padding : 0 × 18px horizontal; row is flex-horizontal, gap 14px
//
// Anatomy (L → R):
//   [icon box 40×40]  [label / sublabel flex-1]  [arrow ›]
//
// States:
//   default  : border #2A2A2A
//   pressed  : border #FFD100  (no opacity change — important for low vision)
//   disabled : opacity 0.4, onTap is a no-op, semantics disabled
//
// Accessibility:
//   The entire row is ONE tappable surface (no nested touchables).
//   Semantics label and hint are explicit props — never derived from label text.
//   Role: button.
// ─────────────────────────────────────────────

class ActionRow extends StatefulWidget {
  /// Display label — rendered UPPERCASE automatically.
  final String label;

  /// Optional muted sub-text beneath the label.
  final String? sublabel;

  /// Icon rendered inside the 40×40 yellow-bordered box.
  /// Typically an [EyerisIcons.*] widget (26×26 or smaller).
  final Widget icon;

  /// Called when the row is tapped. Pass `() {}` as a no-op placeholder.
  final VoidCallback onPress;

  /// When true, the arrow glyph and any danger-specific styling uses
  /// [EyerisColors.danger] (#FF4444) instead of [EyerisColors.primary].
  final bool danger;

  /// When true, row is visually dimmed (opacity 0.4) and ignores taps.
  final bool disabled;

  /// Explicit TalkBack / VoiceOver label — must be descriptive, not just
  /// a repeat of [label]. E.g. "Point and read. Aims camera at text."
  final String semanticsLabel;

  /// Optional TalkBack / VoiceOver hint shown after the label.
  /// E.g. "Double tap to open camera."
  final String? semanticsHint;

  const ActionRow({
    super.key,
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onPress,
    this.danger = false,
    this.disabled = false,
    required this.semanticsLabel,
    this.semanticsHint,
  });

  @override
  State<ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<ActionRow> {
  bool _pressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.disabled) setState(() => _pressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.disabled) {
      setState(() => _pressed = false);
      HapticFeedback.lightImpact();
      widget.onPress();
    }
  }

  void _handleTapCancel() => setState(() => _pressed = false);

  Color get _borderColor {
    if (_pressed) return EyerisColors.borderFocus;
    return EyerisColors.border;
  }

  Color get _arrowColor =>
      widget.danger ? EyerisColors.danger : EyerisColors.primary;

  @override
  Widget build(BuildContext context) {
    final row = Semantics(
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      button: true,
      enabled: !widget.disabled,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          constraints: const BoxConstraints(
            minHeight: EyerisTouchTargets.actionRow,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: EyerisSpacing.base,
          ),
          decoration: BoxDecoration(
            color: EyerisColors.surface,
            border: Border.all(
              color: _borderColor,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon container
              _IconBox(icon: widget.icon),

              const SizedBox(width: 14.0),

              // ── Label + sublabel
              Expanded(
                child: _TextBlock(
                  label: widget.label,
                  sublabel: widget.sublabel,
                ),
              ),

              const SizedBox(width: EyerisSpacing.sm),

              // ── Arrow glyph
              _Arrow(color: _arrowColor),
            ],
          ),
        ),
      ),
    );

    // Disabled overlay — wrap in IgnorePointer + opacity
    if (widget.disabled) {
      return Opacity(
        opacity: 0.4,
        child: IgnorePointer(child: row),
      );
    }

    return row;
  }
}

// ─────────────────────────────────────────────
// PRIVATE SUB-WIDGETS
// Kept private (_) to enforce use through ActionRow.
// ─────────────────────────────────────────────

class _IconBox extends StatelessWidget {
  final Widget icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48.0,
      height: 48.0,
      decoration: BoxDecoration(
        color: EyerisColors.black,
        border: Border.all(
          color: EyerisColors.primary,
          width: EyerisBorders.thick,
        ),
        borderRadius: BorderRadius.circular(EyerisRadii.medium),
      ),
      child: Center(child: icon),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String label;
  final String? sublabel;

  const _TextBlock({required this.label, this.sublabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: EyerisText.rowLabel,
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 2.0),
          Text(
            sublabel!,
            style: EyerisText.rowSub,
          ),
        ],
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final Color color;

  const _Arrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '›',
        style: TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.w900,
          color: color,
          height: 1.0,
        ),
      ),
    );
  }
}
