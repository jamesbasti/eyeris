import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/gesture_layer.dart';
import 'package:eyeris/widgets/gesture_navigation.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/section_label.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/services/double_tap_detector.dart';
import 'package:eyeris/services/haptic_feedback_service.dart';

// ─────────────────────────────────────────────
// COMMUNICATE SCREEN (Phase 3 — UI shell only)
//
// Layout:
//   ScreenHeader "COMMUNICATE" + back button
//   ScrollView:
//     Section "CONNECT"
//       ActionRow: Voice Call
//       ActionRow: Messages
//     Section "ALERTS"
//       ActionRow: Emergency SOS  ← danger variant
//   MicBar  "SAY 'CALL [NAME]'"
//
// SOS long-press will trigger SOSModal in Phase 4.
// ─────────────────────────────────────────────

class CommunicateScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onVoiceCallTap;
  final VoidCallback onMessagesTap;

  /// Short tap on SOS row — announces hold instruction.
  final VoidCallback onSOSTap;

  /// Long press on SOS row — triggers confirmation modal.
  final VoidCallback onSOSLongPress;

  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;
  final GestureLayerConfig? gestureConfig;

  const CommunicateScreen({
    super.key,
    this.onBack          = _noop,
    this.onVoiceCallTap  = _noop,
    this.onMessagesTap   = _noop,
    this.onSOSTap        = sosDefaultTap,
    this.onSOSLongPress  = _noop,
    this.onMicTap        = _noop,
    this.onMicLongPress,
    this.micState        = MicBarState.idle,
    this.gestureConfig,
  });

  static void _noop() {}

  /// Default short-tap behaviour: announces the hold instruction
  /// so the user understands the long-press requirement.
  /// Public so the Navigator shell can reference it without
  /// duplicating the announcement string.
  static void sosDefaultTap() {
    SemanticsService.sendAnnouncement(
      // Use a default view since this is a static method
      WidgetsBinding.instance.platformDispatcher.views.first,
      'Hold for 2 seconds to activate Emergency SOS.',
      TextDirection.ltr,
    );
  }

  @override
  State<CommunicateScreen> createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends State<CommunicateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Communicate screen. 3 options: Voice Call, Messages, '
          'Emergency SOS.',
          TextDirection.ltr,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisColors.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Screen header
                ScreenHeader(
                  title: 'Communicate',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureLayer(
              onBack:     widget.gestureConfig?.onBack,
              onVoice:    widget.gestureConfig?.onVoice,
              screenName: widget.gestureConfig?.screenName ?? 'Communicate screen',
              options:    widget.gestureConfig?.options ??
                  ['Voice Call', 'Messages', 'Emergency SOS'],
              child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                const SectionLabel('Connect'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Voice Call',
                  sublabel: 'Contacts + speed dial',
                  icon: EyerisIcons.phone(size: 28),
                  onPress: widget.onVoiceCallTap,
                  semanticsLabel:
                      'Voice call. Opens contacts list for calling. '
                      'Speed dial available.',
                  semanticsHint: 'Double tap to open contacts.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Messages',
                  sublabel: 'Read aloud + dictate reply',
                  icon: EyerisIcons.message(size: 28),
                  onPress: widget.onMessagesTap,
                  semanticsLabel:
                      'Messages. Reads your messages aloud and lets you '
                      'dictate replies.',
                  semanticsHint: 'Double tap to open messages.',
                ),
                const SizedBox(height: EyerisSpacing.md2),

                const SectionLabel('Alerts'),
                const SizedBox(height: EyerisSpacing.sm),

                _SOSRow(
                  onTap: widget.onSOSTap,
                  onLongPress: widget.onSOSLongPress,
                ),
              ],
            ),
            ),  // GestureLayer
          ),

          MicBar(
            contextLabel: "Say 'Call [Name]'",
            contextHint: 'Or dictate a message',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SOS ROW
// Danger variant of ActionRow with long-press support.
// Separated into its own widget because it needs
// GestureDetector.onLongPress, which ActionRow
// does not currently expose (keeping ActionRow simple).
// ─────────────────────────────────────────────

class _SOSRow extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SOSRow({
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_SOSRow> createState() => _SOSRowState();
}

class _SOSRowState extends State<_SOSRow> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _showTapAgainHint = false;
  late DoubleTapDetector _doubleTapDetector;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _doubleTapDetector = DoubleTapDetector(
      onFirstTap: _handleFirstTap,
      onDoubleTap: _handleDoubleTap,
    );
  }

  @override
  void dispose() {
    _doubleTapDetector.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleFirstTap() {
    // Light haptic on first tap
    HapticFeedbackService.instance.trigger(HapticPattern.light);
    
    // Show "TAP AGAIN" hint
    setState(() => _showTapAgainHint = true);
    
    // Pulse animation
    _pulseController.forward().then((_) => _pulseController.reverse());
    
    // Announce for screen readers
    if (context.mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        'First tap registered. Tap again within 500 milliseconds to activate emergency SOS.',
        TextDirection.ltr,
      );
    }
    
    // Hide hint after timeout
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showTapAgainHint = false);
      }
    });
  }

  void _handleDoubleTap() {
    // Medium haptic on second tap
    HapticFeedbackService.instance.trigger(HapticPattern.medium);
    
    // Hide hint
    setState(() => _showTapAgainHint = false);
    
    // Trigger long press callback (which opens countdown)
    widget.onLongPress();
  }

  void _handleTap() {
    _doubleTapDetector.registerTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Emergency SOS. Hold for 2 seconds to send an emergency '
          'broadcast to your contacts.',
      hint: 'Long press activates SOS. This cannot be undone.',
      button: true,
      child: GestureDetector(
        onTapDown:  (_) => setState(() => _pressed = true),
        onTapUp:    (_) { setState(() => _pressed = false); _handleTap(); },
        onTapCancel: () => setState(() => _pressed = false),
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
              color: _pressed ? EyerisColors.danger : EyerisColors.border,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EyerisColors.black,
                  border: Border.all(
                    color: EyerisColors.primary,
                    width: EyerisBorders.thick,
                  ),
                  borderRadius: BorderRadius.circular(EyerisRadii.medium),
                ),
                child: Center(child: EyerisIcons.warning(size: 22)),
              ),

              const SizedBox(width: 14.0),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EMERGENCY SOS',
                      style: EyerisText.rowLabel,
                    ),
                    const SizedBox(height: 2),
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Text(
                          _showTapAgainHint ? 'TAP AGAIN!' : 'Double tap to activate',
                          style: EyerisText.rowSub.copyWith(
                            color: _showTapAgainHint 
                                ? EyerisColors.primary 
                                : EyerisColors.textMuted,
                            fontWeight: _showTapAgainHint 
                                ? FontWeight.w700 
                                : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: EyerisSpacing.sm),

              // Danger arrow
              ExcludeSemantics(
                child: Text(
                  '›',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                    color: EyerisColors.danger,
                    height: 1.0,
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
