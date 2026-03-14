// lib/widgets/action_row.dart
// Tappable list row used in all sub-screens. Min height 80px, border feedback on press.

import 'package:flutter/material.dart';

import 'package:eyeris/core/app_theme.dart';

/// Sublabel color per Sense Hub spec (slightly darker than textMuted).
const Color _sublabelColor = Color(0xFF777777);

/// Action row: icon container + label/sublabel + arrow. Min height 80px.
/// Entire row is one touchable; pressed state changes border to primary (no opacity).
class ActionRow extends StatefulWidget {
  const ActionRow({
    super.key,
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onPress,
    this.danger = false,
    required this.accessibilityLabel,
    this.accessibilityHint,
    this.testID,
    this.enabled = true,
  });

  final String label;
  final String? sublabel;
  final Widget icon;
  final VoidCallback onPress;
  final bool danger;
  final String accessibilityLabel;
  final String? accessibilityHint;
  final String? testID;
  final bool enabled;

  @override
  State<ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<ActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.enabled
        ? EyerisTheme.border
        : _pressed
            ? EyerisTheme.primary
            : EyerisTheme.border;
    final arrowColor = widget.danger ? EyerisTheme.danger : EyerisTheme.primary;

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
            constraints: BoxConstraints(minHeight: EyerisTheme.touchActionRow),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: EyerisTheme.surface,
              borderRadius: BorderRadius.circular(EyerisTheme.radiusLarge),
              border: Border.all(color: borderColor, width: EyerisTheme.borderThick),
            ),
            child: Row(
              children: [
                // Icon container: 40×40, radius 10, background #000, border 2px primary
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EyerisTheme.primary, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: IconTheme(
              data: const IconThemeData(color: EyerisTheme.primary, size: 26),
              child: widget.icon,
            ),
                ),
                const SizedBox(width: 14),
                // Text block (flex: 1)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label.toUpperCase(),
                        style: typography(
                          size: 'md',
                          weight: FontWeight.w700,
                          color: EyerisTheme.textPrimary,
                          letterSpacingKey: 'normal',
                        ).copyWith(letterSpacing: 13 * 0.06),
                      ),
                      if (widget.sublabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.sublabel!,
                          style: typography(
                            size: 'xs',
                            color: _sublabelColor,
                            letterSpacingKey: 'tight',
                          ).copyWith(letterSpacing: 9 * 0.04),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Arrow: "›" 18px, primary or danger
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: arrowColor,
                    fontFamily: EyerisTheme.fontFamily,
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

// ---------------------------------------------------------------------------
// Usage example (from Sense Hub Prompt 02):
//
// ActionRow(
//   label: 'POINT & READ',
//   sublabel: 'Camera → instant speech',
//   icon: CameraIcon(size: 26, color: EyerisTheme.primary),
//   onPress: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CameraScreen())),
//   accessibilityLabel: 'Point and read. Aims camera at text and reads it aloud.',
//   accessibilityHint: 'Double tap to open camera',
// )
//
// For danger variant (e.g. Emergency SOS):
//
// ActionRow(
//   label: 'EMERGENCY SOS',
//   sublabel: 'Hold 2 sec to broadcast',
//   icon: WarningIcon(size: 26),
//   onPress: () {},
//   danger: true,
//   accessibilityLabel: 'Emergency SOS. Hold for 2 seconds to send an emergency broadcast.',
//   accessibilityHint: 'Long press activates SOS. This cannot be undone.',
// )
