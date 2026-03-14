import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/section_label.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// IDENTIFY SCREEN  (Phase 3 — UI shell only)
//
// Layout:
//   AppStatusBar
//   ScreenHeader "IDENTIFY" + back button
//   ScrollView:
//     Section "DESCRIBE"
//       ActionRow: Scene Describe
//       ActionRow: Find Person
//       ActionRow: Color Detect
//   MicBar  "SAY 'DESCRIBE THIS'"
//
// Note: "Scene Describe" will push to CameraScreen
// in the functionality pass (Phase 5).
// ─────────────────────────────────────────────

class IdentifyScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSceneDescribeTap;
  final VoidCallback onFindPersonTap;
  final VoidCallback onColorDetectTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;

  const IdentifyScreen({
    super.key,
    this.onBack             = _noop,
    this.onSceneDescribeTap = _noop,
    this.onFindPersonTap    = _noop,
    this.onColorDetectTap   = _noop,
    this.onMicTap           = _noop,
    this.onMicLongPress,
    this.micState           = MicBarState.idle,
  });

  static void _noop() {}

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Identify screen. 3 options: Scene Describe, Find Person, '
          'Color Detect.',
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
                const AppStatusBar(),
                ScreenHeader(
                  title: 'Identify',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                const SectionLabel('Describe'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Scene Describe',
                  sublabel: 'Full AI description',
                  icon: EyerisIcons.camera(size: 22),
                  onPress: widget.onSceneDescribeTap,
                  semanticsLabel:
                      'Scene describe. Get full AI description of surroundings.',
                  semanticsHint: 'Double tap to start camera.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Find Person',
                  sublabel: 'Face recognition',
                  icon: EyerisIcons.person(size: 22),
                  onPress: widget.onFindPersonTap,
                  semanticsLabel:
                      'Find person. Use face recognition to locate people.',
                  semanticsHint: 'Double tap to start face detection.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Color Detect',
                  sublabel: 'Name any color aloud',
                  icon: EyerisIcons.colorDetect(size: 22),
                  onPress: widget.onColorDetectTap,
                  semanticsLabel:
                      'Color detect. Point camera to identify colors.',
                  semanticsHint: 'Double tap to start color detection.',
                ),
              ],
            ),
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
