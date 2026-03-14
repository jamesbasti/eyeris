import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/hub_card.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/profile_avatar.dart' as profile;
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// HOME SCREEN
// Phase 2 — UI shell only.
// Navigation callbacks are no-ops until Phase 4 (Navigator shell).
//
// Layout (top → bottom):
//   AppStatusBar
//   ScreenHeader "EYERIS" + ProfileAvatar
//   HubCardGrid (4 cards, 2×2)
//   MicBar
// ─────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  // Navigation callbacks — pass real routes in Phase 4.
  // Defaults to no-op so UI builds without a Navigator.
  final VoidCallback onReadTap;
  final VoidCallback onNavigateTap;
  final VoidCallback onIdentifyTap;
  final VoidCallback onCommunicateTap;
  final VoidCallback onProfileTap;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;

  const HomeScreen({
    super.key,
    this.onReadTap = _noop,
    this.onNavigateTap = _noop,
    this.onIdentifyTap = _noop,
    this.onCommunicateTap = _noop,
    this.onProfileTap = _noop,
    this.onMicTap = _noop,
    this.onMicLongPress,
    this.micState = MicBarState.idle,
  });

  static void _noop() {}

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Announce screen on mount for TalkBack / VoiceOver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Eyeris home. 4 options available: Read, Navigate, Identify, Communicate.',
          TextDirection.ltr,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EyerisColors.background,

      // No AppBar — we use our own ScreenHeader
      body: Column(
        children: [
          // ── System safe area (notch / status bar)
          SafeArea(bottom: false, child: _buildTopBar()),

          // ── Hub card grid — fills remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              child: HubCardGrid(
                gap: 10,
                cards: [
                  _buildCard(
                    label: 'Read',
                    sublabel: 'Scan text &\ndocuments',
                    icon: EyerisIcons.read(size: 36),
                    badge: 'AAA',
                    semanticsLabel: 'Read. Scan text and documents.',
                    semanticsHint: 'Double tap to open Read screen.',
                    onTap: widget.onReadTap,
                  ),
                  _buildCard(
                    label: 'Navigate',
                    sublabel: 'Indoor &\noutdoor',
                    icon: EyerisIcons.navigate(size: 36),
                    semanticsLabel: 'Navigate. Indoor and outdoor guidance.',
                    semanticsHint: 'Double tap to open Navigate screen.',
                    onTap: widget.onNavigateTap,
                  ),
                  _buildCard(
                    label: 'Identify',
                    sublabel: 'Objects, faces\n& colors',
                    icon: EyerisIcons.identify(size: 36),
                    semanticsLabel: 'Identify. Describe objects, faces and colors.',
                    semanticsHint: 'Double tap to open Identify screen.',
                    onTap: widget.onIdentifyTap,
                  ),
                  _buildCard(
                    label: 'Communicate',
                    sublabel: 'Calls, messages\n& alerts',
                    icon: EyerisIcons.communicate(size: 36),
                    semanticsLabel: 'Communicate. Calls, messages and alerts.',
                    semanticsHint: 'Double tap to open Communicate screen.',
                    onTap: widget.onCommunicateTap,
                  ),
                ],
              ),
            ),
          ),

          // ── Persistent mic bar — pinned to bottom
          MicBar(
            contextLabel: 'Speak to control',
            contextHint: 'Say a command or hold for\ncontinuous listening',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }

  // ── Top bar: status + header stacked
  Widget _buildTopBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScreenHeader(
          title: 'Eyeris',
          // No back button on home screen
          rightElement: profile.ProfileAvatar(onTap: widget.onProfileTap),
        ),
      ],
    );
  }

  // ── Card factory — keeps build() clean
  HubCard _buildCard({
    required String label,
    required String? sublabel,
    required Widget icon,
    String? badge,
    required String semanticsLabel,
    required String semanticsHint,
    required VoidCallback onTap,
  }) {
    return HubCard(
      label: label,
      sublabel: sublabel,
      icon: icon,
      badge: badge,
      onTap: onTap,
      semanticsLabel: semanticsLabel,
      semanticsHint: semanticsHint,
    );
  }
}
