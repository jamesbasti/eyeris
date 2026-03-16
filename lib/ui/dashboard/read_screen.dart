import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/section_label.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/ui/camera/text_camera_screen.dart';
import 'dart:developer' as developer;

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
  final FlutterTts _flutterTts = FlutterTts();
  bool _showTextCamera = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
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

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5); // Slower for better accessibility
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Get available voices and choose best one
    final voices = await _flutterTts.getVoices;
    developer.log('Available voices count: ${voices.length}');
    
    // Try to find a more natural voice
    String selectedVoice = '';
    for (var voice in voices) {
      // Check if voice is a Map or has name property
      String voiceName = '';
      if (voice is Map) {
        voiceName = voice['name']?.toString() ?? '';
      } else {
        voiceName = voice.name?.toString() ?? '';
      }
      
      developer.log('Checking voice: "$voiceName"');
      
      if (voiceName.toLowerCase().contains('samantha') || 
          voiceName.toLowerCase().contains('alex') ||
          voiceName.toLowerCase().contains('daniel') ||
          voiceName.toLowerCase().contains('karen')) {
        selectedVoice = voiceName;
        break;
      }
    }
    
    // If no specific voice found, use the first available
    if (selectedVoice.isEmpty && voices.isNotEmpty) {
      final firstVoice = voices.first;
      if (firstVoice is Map) {
        selectedVoice = firstVoice['name']?.toString() ?? '';
      } else {
        selectedVoice = firstVoice.name?.toString() ?? '';
      }
    }
    
    if (selectedVoice.isNotEmpty) {
      await _flutterTts.setVoice({"name": selectedVoice, "locale": "en-US"});
      developer.log('Using voice: $selectedVoice');
    }
    
    // Add speech completion handler
    _flutterTts.setCompletionHandler(() {
      // Speech completed - you can add logic here if needed
    });
    
    // Add error handler
    _flutterTts.setErrorHandler((msg) {
      developer.log('TTS Error: $msg');
    });
  }

  void _onPointAndReadTap() {
    setState(() {
      _showTextCamera = true;
    });
  }

  void _onTextCameraBack() {
    // Stop any ongoing speech when going back
    _flutterTts.stop();
    setState(() {
      _showTextCamera = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisColors.background,
      body: Stack(
        children: [
          // Main content
          Column(
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
                      onPress: _onPointAndReadTap,
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
                          'Scan document. Convert PDF, photos, receipts to text.',
                      semanticsHint: 'Double tap to scan document.',
                    ),
                    const SizedBox(height: EyerisSpacing.md2),

                    const SectionLabel('Settings'),
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

          // Text camera overlay
          if (_showTextCamera)
            Positioned.fill(
              child: TextCameraScreen(
                onBack: _onTextCameraBack,
                onTextDetected: () {
                  // Text was detected and spoken
                  // You can add additional logic here if needed
                }),
            ),
        ],
      ),
    );
  }
}
