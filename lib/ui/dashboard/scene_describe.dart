import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// SCENE DESCRIBE SCREEN  (Phase 3 — UI shell only)
//
// Layout:
//   AppStatusBar
//   ScreenHeader "SCENE DESCRIBE" + back button
//   ScrollView:
//     Section "CAMERA ACTIONS"
//       ActionRow: Scene Describe
//   MicBar  "SAY 'DESCRIBE SCENE'"
// ─────────────────────────────────────────────

class SceneDescribeScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;

  const SceneDescribeScreen({
    super.key,
    required this.onBack,
    required this.onMicTap,
    this.onMicLongPress,
    this.micState = MicBarState.idle,
  });

  @override
  State<SceneDescribeScreen> createState() => _SceneDescribeScreenState();
}

class _SceneDescribeScreenState extends State<SceneDescribeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Scene Describe screen. Camera ready to describe what you see.',
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
                  title: 'Scene Describe',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EyerisIcons.identify(size: 64),
                  const SizedBox(height: EyerisSpacing.md),
                  Text(
                    'Scene Description Camera',
                    style: TextStyle(
                      fontSize: 18,
                      color: EyerisColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: EyerisSpacing.sm),
                  Text(
                    'Point camera at objects to hear descriptions',
                    style: TextStyle(
                      fontSize: 14,
                      color: EyerisColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
