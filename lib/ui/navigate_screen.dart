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

// ─────────────────────────────────────────────
// NAVIGATE SCREEN  (Phase 3 — UI shell only)
//
// Layout:
//   AppStatusBar
//   ScreenHeader "NAVIGATE" + back button
//   ScrollView:
//     Section "MODE"
//       ActionRow: Walk Mode
//       ActionRow: Indoor Map
//     Section "QUICK ACTIONS"
//       ActionRow: Nearest Bus
//   MicBar  "SAY 'TAKE ME TO…'"
// ─────────────────────────────────────────────

class NavigateScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onWalkModeTap;
  final VoidCallback onIndoorMapTap;
  final VoidCallback onNearestBusTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;
  final GestureLayerConfig? gestureConfig;

  const NavigateScreen({
    super.key,
    this.onBack          = _noop,
    this.onWalkModeTap   = _noop,
    this.onIndoorMapTap  = _noop,
    this.onNearestBusTap = _noop,
    this.onMicTap        = _noop,
    this.onMicLongPress,
    this.micState        = MicBarState.idle,
    this.gestureConfig,
  });

  static void _noop() {}

  @override
  State<NavigateScreen> createState() => _NavigateScreenState();
}

class _NavigateScreenState extends State<NavigateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Navigate screen. 3 options: Walk Mode, Indoor Map, Nearest Bus.',
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
                  title: 'Navigate',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureLayer(
              onBack:     widget.gestureConfig?.onBack,
              onVoice:    widget.gestureConfig?.onVoice,
              screenName: widget.gestureConfig?.screenName ?? 'Navigate screen',
              options:    widget.gestureConfig?.options ??
                  ['Walk Mode', 'Indoor Map', 'Nearest Bus'],
              child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                const SectionLabel('Mode'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Walk Mode',
                  sublabel: 'Haptic + audio turns',
                  icon: EyerisIcons.walk(size: 28),
                  onPress: widget.onWalkModeTap,
                  semanticsLabel:
                      'Walk mode. Provides haptic and audio turn guidance.',
                  semanticsHint: 'Double tap to toggle walk mode.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Indoor Map',
                  sublabel: 'Obstacle detection on',
                  icon: EyerisIcons.indoorMap(size: 28),
                  onPress: widget.onIndoorMapTap,
                  semanticsLabel:
                      'Indoor map. Navigate indoors with obstacle detection.',
                  semanticsHint: 'Double tap to open indoor map.',
                ),
                const SizedBox(height: EyerisSpacing.md2),

                const SectionLabel('Quick Actions'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Nearest Bus',
                  sublabel: 'Transit + live arrival',
                  icon: EyerisIcons.bus(size: 28),
                  onPress: widget.onNearestBusTap,
                  semanticsLabel:
                      'Nearest bus. Find transit options with live arrivals.',
                  semanticsHint: 'Double tap to find nearest bus stop.',
                ),
              ],
            ),
            ),  // GestureLayer
          ),

          MicBar(
            contextLabel: "Say 'Take Me To…'",
            contextHint: 'Speak your destination',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }
}
