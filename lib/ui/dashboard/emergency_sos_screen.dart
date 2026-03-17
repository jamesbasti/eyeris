import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/gesture_layer.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/section_label.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// EMERGENCY SOS SCREEN
//
// Layout:
//   ScreenHeader "EMERGENCY SOS" + back button
//   ScrollView:
//     Section "EMERGENCY CONTACTS"
//       ActionRow: Contact 1
//       ActionRow: Contact 2
//       ActionRow: Add Contact
//     Section "QUICK ACTIONS"
//       ActionRow: Call Emergency Services
//       ActionRow: Send Location
//       ActionRow: Activate Siren
//   MicBar  "SAY 'EMERGENCY'"
// ─────────────────────────────────────────────

class EmergencySOSScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onContact1Tap;
  final VoidCallback onContact2Tap;
  final VoidCallback onAddContactTap;
  final VoidCallback onEmergencyServicesTap;
  final VoidCallback onSendLocationTap;
  final VoidCallback onActivateSirenTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;
  final VoidCallback? onGestureBack;
final VoidCallback? onGestureVoice;
final String? gestureScreenName;
final List<String>? gestureOptions;

  const EmergencySOSScreen({
    super.key,
    this.onBack = _noop,
    this.onContact1Tap = _noop,
    this.onContact2Tap = _noop,
    this.onAddContactTap = _noop,
    this.onEmergencyServicesTap = _noop,
    this.onSendLocationTap = _noop,
    this.onActivateSirenTap = _noop,
    this.onMicTap = _noop,
    this.onMicLongPress,
    this.micState = MicBarState.idle,
    this.onGestureBack,
    this.onGestureVoice,
    this.gestureScreenName,
    this.gestureOptions,
  });

  static void _noop() {}

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Emergency SOS screen. Quick actions and emergency contacts.',
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
                // ── Screen header with emergency styling
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EyerisSpacing.md2,
                    vertical: EyerisSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: EyerisColors.danger.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(
                        color: EyerisColors.danger.withValues(alpha: 0.3),
                        width: EyerisBorders.header,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Back button
                      Semantics(
                        label: 'Back',
                        button: true,
                        child: GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            width: EyerisTouchTargets.backButton,
                            height: EyerisTouchTargets.backButton,
                            decoration: BoxDecoration(
                              color: EyerisColors.danger,
                              borderRadius: BorderRadius.circular(EyerisRadii.small),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                color: EyerisColors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: EyerisSpacing.md),

                      // Title with emergency icon
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EyerisIcons.warning(size: 24, color: EyerisColors.danger),
                            const SizedBox(width: EyerisSpacing.sm),
                            Text(
                              'EMERGENCY SOS',
                              style: EyerisText.screenTitle.copyWith(
                                color: EyerisColors.danger,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Spacer to center title
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureLayer(
              onBack: widget.onGestureBack,
              onVoice: widget.onGestureVoice,
              screenName: widget.gestureScreenName ?? 'Emergency SOS screen',
              options: widget.gestureOptions ?? [
                'Contact 1',
                'Contact 2',
                'Add Contact',
                'Emergency Services',
                'Send Location',
                'Activate Siren'
              ],
              child: ListView(
                padding: const EdgeInsets.all(EyerisSpacing.md2),
                children: [
                  const SectionLabel('Emergency Contacts'),
                  const SizedBox(height: EyerisSpacing.sm),

                  ActionRow(
                    label: 'Contact 1',
                    sublabel: 'Mom - Mobile',
                    icon: EyerisIcons.phone(size: 28),
                    onPress: widget.onContact1Tap,
                    semanticsLabel:
                        'Contact 1. Call Mom on mobile.',
                    semanticsHint: 'Double tap to call.',
                  ),
                  const SizedBox(height: EyerisSpacing.sm),

                  ActionRow(
                    label: 'Contact 2',
                    sublabel: 'Dad - Mobile',
                    icon: EyerisIcons.phone(size: 28),
                    onPress: widget.onContact2Tap,
                    semanticsLabel:
                        'Contact 2. Call Dad on mobile.',
                    semanticsHint: 'Double tap to call.',
                  ),
                  const SizedBox(height: EyerisSpacing.sm),

                  ActionRow(
                    label: 'Add Contact',
                    sublabel: 'Setup emergency contact',
                    icon: Icon(Icons.add, size: 28, color: EyerisColors.primary),
                    onPress: widget.onAddContactTap,
                    semanticsLabel:
                        'Add contact. Setup new emergency contact.',
                    semanticsHint: 'Double tap to add contact.',
                  ),
                  const SizedBox(height: EyerisSpacing.md2),

                  const SectionLabel('Quick Actions'),
                  const SizedBox(height: EyerisSpacing.sm),

                  _EmergencyActionRow(
                    label: 'Emergency Services',
                    sublabel: 'Call 911',
                    icon: EyerisIcons.warning(size: 28),
                    onPress: widget.onEmergencyServicesTap,
                    semanticsLabel:
                        'Emergency Services. Call 911 immediately.',
                    semanticsHint: 'Double tap to call 911.',
                  ),
                  const SizedBox(height: EyerisSpacing.sm),

                  _EmergencyActionRow(
                    label: 'Send Location',
                    sublabel: 'Share GPS with contacts',
                    icon: EyerisIcons.navigate(size: 28),
                    onPress: widget.onSendLocationTap,
                    semanticsLabel:
                        'Send Location. Share your GPS location with emergency contacts.',
                    semanticsHint: 'Double tap to send location.',
                  ),
                  const SizedBox(height: EyerisSpacing.sm),

                  _EmergencyActionRow(
                    label: 'Activate Siren',
                    sublabel: 'Play loud alarm sound',
                    icon: Icon(Icons.volume_up, size: 28, color: EyerisColors.primary),
                    onPress: widget.onActivateSirenTap,
                    semanticsLabel:
                        'Activate Siren. Play a loud alarm to attract attention.',
                    semanticsHint: 'Double tap to activate siren.',
                  ),
                ],
              ),
            ),
          ),

          MicBar(
            contextLabel: "Say 'Emergency'",
            contextHint: 'Or say a contact name',
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
// EMERGENCY ACTION ROW
// Danger variant of ActionRow for critical actions.
// ─────────────────────────────────────────────

class _EmergencyActionRow extends StatefulWidget {
  final String label;
  final String? sublabel;
  final Widget icon;
  final VoidCallback onPress;
  final String semanticsLabel;
  final String semanticsHint;

  const _EmergencyActionRow({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.onPress,
    required this.semanticsLabel,
    required this.semanticsHint,
  });

  @override
  State<_EmergencyActionRow> createState() => _EmergencyActionRowState();
}

class _EmergencyActionRowState extends State<_EmergencyActionRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      hint: widget.semanticsHint,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) { setState(() => _pressed = false); widget.onPress(); },
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
            color: _pressed 
                ? EyerisColors.danger.withValues(alpha: 0.1)
                : EyerisColors.surface,
            border: Border.all(
              color: _pressed ? EyerisColors.danger : EyerisColors.danger.withValues(alpha: 0.5),
              width: _pressed ? EyerisBorders.thick : EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box with emergency styling
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EyerisColors.danger,
                  border: Border.all(
                    color: EyerisColors.danger,
                    width: EyerisBorders.thick,
                  ),
                  borderRadius: BorderRadius.circular(EyerisRadii.medium),
                ),
                child: Center(
                  child: IconTheme(
                    data: const IconThemeData(
                      color: EyerisColors.white,
                      size: 22,
                    ),
                    child: widget.icon,
                  ),
                ),
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
                      widget.label,
                      style: EyerisText.rowLabel.copyWith(
                        color: EyerisColors.danger,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.sublabel!,
                        style: EyerisText.rowSub.copyWith(
                          color: EyerisColors.danger.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: EyerisSpacing.sm),

              // Emergency arrow
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
