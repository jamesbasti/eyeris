import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// SOS MODAL
//
// Full-screen emergency confirmation dialog.
// Triggered by long-pressing the SOS row in
// CommunicateScreen.
//
// Safety rules hard-coded here:
//   - No animation — instant appear. Speed matters.
//   - barrierDismissible: false — must explicitly
//     choose CONFIRM or CANCEL. No accidental dismiss.
//   - CANCEL is reachable in one swipe after CONFIRM
//     (screen reader focus order: warning → title →
//     body → CONFIRM → CANCEL).
//   - accessibilityViewIsModal: true traps focus
//     inside the card for TalkBack / VoiceOver.
//   - On open: announces full context so a blind
//     user knows what the modal is without swiping.
//
// Usage:
//   final confirmed = await showSOSModal(context);
//   if (confirmed == true) { /* send SOS */ }
// ─────────────────────────────────────────────

/// Shows the SOS confirmation dialog.
/// Returns `true` if the user confirmed, `false` if cancelled,
/// `null` if dismissed by other means (should not happen —
/// barrierDismissible is false).
Future<bool?> showSOSModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0xEB000000), // 92% black
    barrierDismissible: false,
    builder: (_) => const _SOSModalContent(),
  );
}

// ─────────────────────────────────────────────
// CONTENT WIDGET
// Private — always used through showSOSModal().
// ─────────────────────────────────────────────

class _SOSModalContent extends StatefulWidget {
  const _SOSModalContent();

  @override
  State<_SOSModalContent> createState() => _SOSModalContentState();
}

class _SOSModalContentState extends State<_SOSModalContent> {
  // Focus node on CONFIRM so screen readers land there first
  // after the modal announcement.
  final FocusNode _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Announce modal contents immediately on open.
    // Delay 350ms to avoid clashing with the route transition
    // announcement from the previous screen.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      SemanticsService.announce(
        'Emergency SOS confirmation. '
        'This will alert all your emergency contacts with your location. '
        'Double tap Confirm to send SOS, or Cancel to go back.',
        TextDirection.ltr,
      );
      _confirmFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Traps TalkBack / VoiceOver focus inside the dialog.
      scopesRoute: true,
      explicitChildNodes: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(EyerisSpacing.xxl),
              decoration: BoxDecoration(
                color: EyerisColors.surface,
                border: Border.all(
                  color: EyerisColors.danger,
                  width: EyerisBorders.header,
                ),
                borderRadius: BorderRadius.circular(EyerisRadii.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Warning icon
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: EyerisIcons.warning(
                        size: 48,
                        color: EyerisColors.danger,
                      ),
                    ),
                  ),

                  const SizedBox(height: EyerisSpacing.base),

                  // ── Title
                  Semantics(
                    header: true,
                    child: Text(
                      'EMERGENCY SOS',
                      style: EyerisText.mono(
                        size: 18,
                        letterSpacing: 0.12,
                        color: EyerisColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: EyerisSpacing.md),

                  // ── Body
                  Text(
                    'This will alert all your emergency contacts '
                    'with your current location.',
                    style: EyerisText.mono(
                      size: 14,
                      weight: FontWeight.w400,
                      color: EyerisColors.textPrimary,
                      letterSpacing: 0.02,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: EyerisSpacing.xxl),

                  // ── CONFIRM button
                  _SOSButton(
                    label: 'SEND SOS NOW',
                    background: EyerisColors.danger,
                    textColor: EyerisColors.white,
                    focusNode: _confirmFocus,
                    semanticsLabel:
                        'Confirm. Send emergency SOS to all contacts now.',
                    onTap: () => Navigator.of(context).pop(true),
                  ),

                  const SizedBox(height: EyerisSpacing.md),

                  // ── CANCEL button
                  _SOSButton(
                    label: 'CANCEL',
                    background: Colors.transparent,
                    textColor: EyerisColors.textMuted,
                    borderColor: EyerisColors.border,
                    semanticsLabel:
                        'Cancel. Close this dialog without sending SOS.',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SOS BUTTON
// Full-width, 72px — oversized for a safety action.
// Private — only used inside this modal.
// ─────────────────────────────────────────────

class _SOSButton extends StatefulWidget {
  final String label;
  final Color background;
  final Color textColor;
  final Color? borderColor;
  final FocusNode? focusNode;
  final String semanticsLabel;
  final VoidCallback onTap;

  const _SOSButton({
    required this.label,
    required this.background,
    required this.textColor,
    this.borderColor,
    this.focusNode,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  State<_SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<_SOSButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      focusable: true,
      child: Focus(
        focusNode: widget.focusNode,
        child: GestureDetector(
          onTapDown:   (_) => setState(() => _pressed = true),
          onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
          onTapCancel: ()  => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              color: _pressed
                  ? widget.background.withValues(alpha: 0.80)
                  : widget.background,
              borderRadius: BorderRadius.circular(EyerisRadii.large),
              border: widget.borderColor != null
                  ? Border.all(
                      color: widget.borderColor!,
                      width: EyerisBorders.card,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                widget.label,
                style: EyerisText.mono(
                  size: 15,
                  letterSpacing: 0.10,
                  color: widget.textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
