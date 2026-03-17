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
// COLOR DETECT SCREEN  (Phase 3 — UI shell only)
//
// Layout:
//   AppStatusBar
//   ScreenHeader "COLOR DETECT" + back button
//   ScrollView:
//     Section "CAMERA ACTIONS"
//       ActionRow: Color Detect
//   MicBar  "SAY 'WHAT COLOR IS THIS'"
//
// Note: "Color Detect" pushes to ColorDetectCameraScreen
// ─────────────────────────────────────────────

class ColorDetectScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSceneDescribeTap;
  final VoidCallback onFindPersonTap;
  final VoidCallback onColorDetectTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;
  final GestureLayerConfig? gestureConfig;

  const ColorDetectScreen({
    super.key,
    required this.onBack,
    required this.onSceneDescribeTap,
    required this.onFindPersonTap,
    required this.onColorDetectTap,
    required this.onMicTap,
    this.onMicLongPress,
    this.micState = MicBarState.idle,
    this.gestureConfig,
  });

  @override
  State<ColorDetectScreen> createState() => _ColorDetectScreenState();
}

class _ColorDetectScreenState extends State<ColorDetectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Color Detect screen. Camera ready to identify colors.',
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
                  title: 'Identify',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: GestureLayer(
              onBack:     widget.gestureConfig?.onBack,
              onVoice:    widget.gestureConfig?.onVoice,
              screenName: widget.gestureConfig?.screenName ?? 'Identify screen',
              options:    widget.gestureConfig?.options ??
                  ['Scene Describe', 'Find Person', 'Color Detect'],
              child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                const SectionLabel('Describe'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Scene Describe',
                  sublabel: 'Full AI description',
                  icon: EyerisIcons.camera(size: 28),
                  onPress: widget.onSceneDescribeTap,
                  semanticsLabel:
                      'Scene describe. Get full AI description of surroundings.',
                  semanticsHint: 'Double tap to start camera.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Find Person',
                  sublabel: 'Face recognition',
                  icon: EyerisIcons.person(size: 28),
                  onPress: widget.onFindPersonTap,
                  semanticsLabel:
                      'Find person. Use face recognition to locate people.',
                  semanticsHint: 'Double tap to start face detection.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Color Detect',
                  sublabel: 'Name any color aloud',
                  icon: EyerisIcons.colorDetect(size: 28),
                  onPress: widget.onColorDetectTap,
                  semanticsLabel:
                      'Color detect. Point camera to identify colors.',
                  semanticsHint: 'Double tap to start color detection.',
                ),
              ],
            ),
            ),  // GestureLayer
          ),

          MicBar(
            contextLabel: "Say 'Describe This'",
            contextHint: 'Or tap to point camera',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }
}
