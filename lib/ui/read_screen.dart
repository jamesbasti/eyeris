import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/section_label.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// READ SCREEN  (Phase 3 — UI shell only)
//
// Layout:
//   AppStatusBar
//   ScreenHeader "READ" + back button
//   ScrollView:
//     Section "CAPTURE"
//       ActionRow: Point & Read
//       ActionRow: Scan Document
//     Section "ADJUST"
//       ActionRow: Reading Speed
//       ActionRow: Voice & Language
//   MicBar  "SAY 'SCAN NOW'"
//
// All onTap callbacks default to no-ops.
// Wire real actions in the functionality pass (Phase 5).
// ─────────────────────────────────────────────

class ReadScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onPointAndReadTap;
  final VoidCallback onScanDocumentTap;
  final VoidCallback onReadingSpeedTap;
  final VoidCallback onVoiceLanguageTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;

  const ReadScreen({
    super.key,
    this.onBack             = _noop,
    this.onPointAndReadTap  = _noop,
    this.onScanDocumentTap  = _noop,
    this.onReadingSpeedTap  = _noop,
    this.onVoiceLanguageTap = _noop,
    this.onMicTap           = _noop,
    this.onMicLongPress,
    this.micState           = MicBarState.idle,
  });

  static void _noop() {}

  @override
  State<ReadScreen> createState() => _ReadScreenState();
}

class _ReadScreenState extends State<ReadScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // Use the modern sendAnnouncement API with correct signature
        SemanticsService.sendAnnouncement(
          View.of(context), // FlutterView parameter
          'Read screen. 4 options: Point and Read, Scan Document, '
          'Reading Speed, Voice and Language.',
          TextDirection.ltr, // TextDirection parameter
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
                  title: 'Read',
                  onBack: widget.onBack,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                const SectionLabel('Capture'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Point & Read',
                  sublabel: 'Camera → instant speech',
                  icon: EyerisIcons.camera(size: 28),
                  onPress: widget.onPointAndReadTap,
                  semanticsLabel:
                      'Point and read. Aims camera at text and reads it aloud.',
                  semanticsHint: 'Double tap to open camera.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Scan Document',
                  sublabel: 'PDF, photo, receipt',
                  icon: EyerisIcons.document(size: 28),
                  onPress: widget.onScanDocumentTap,
                  semanticsLabel:
                      'Scan document. Import a PDF, photo, or receipt for reading.',
                  semanticsHint: 'Double tap to open file picker.',
                ),
                const SizedBox(height: EyerisSpacing.md2),

                const SectionLabel('Adjust'),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Reading Speed',
                  sublabel: 'Slow · Normal · Fast',
                  icon: EyerisIcons.clock(size: 28),
                  onPress: widget.onReadingSpeedTap,
                  semanticsLabel:
                      'Reading speed. Currently set to normal. Double tap to change.',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Voice & Language',
                  sublabel: 'English · Filipino · more',
                  icon: EyerisIcons.voice(size: 28),
                  onPress: widget.onVoiceLanguageTap,
                  semanticsLabel:
                      'Voice and language settings. Currently English. '
                      'Double tap to change.',
                ),
              ],
            ),
          ),

          MicBar(
            contextLabel: "Say 'Scan Now'",
            contextHint: 'Or point camera at text',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }
}
