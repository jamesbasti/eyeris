import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';

// ─────────────────────────────────────────────
// SECTION LABEL
// Muted all-caps category divider used above
// groups of ActionRows on sub-screens.
//
// Spec:
//   Font   : 9px monospace, #B89500, letter-spacing 0.14em, bold
//   Padding: top 4px, bottom 2px, left 2px
//   No background, no border, no underline
//   Hidden from screen readers — it is purely organisational;
//   the ActionRow semantics labels carry all meaning.
// ─────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;

  /// Extra top margin before this label (default 0 — caller controls spacing).
  final double topMargin;

  const SectionLabel(
    this.text, {
    super.key,
    this.topMargin = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.only(
          top: topMargin,
          left: 2.0,
          bottom: 2.0,
        ),
        child: Text(
          text.toUpperCase(),
          style: EyerisText.sectionLabel,
        ),
      ),
    );
  }
}
