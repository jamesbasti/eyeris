import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/hub_card.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/profile_avatar.dart' as profile;
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';
import 'package:eyeris/ui/profile_screen.dart';
import 'package:eyeris/services/profile_notifier.dart';

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
  final OnboardingProfile? profile;
  final ValueChanged<OnboardingProfile>? onProfileChanged;

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
    this.profile,
    this.onProfileChanged,
  });

  static void _noop() {}

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OnboardingProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    
    // Listen to profile changes from global notifier
    profileNotifier.addListener(_onProfileChanged);
    
    // Announce screen on mount for TalkBack / VoiceOver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Eyeris home. 4 options available: Read, Scene Describe, Color Detect, Communicate.',
          TextDirection.ltr,
        );
      }
    });
  }

  @override
  void dispose() {
    profileNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      setState(() {
        _currentProfile = widget.profile;
      });
    }
  }

  void _onProfileChanged() {
    if (mounted) {
      final newProfile = profileNotifier.profile;
      if (newProfile != _currentProfile) {
        setState(() {
          _currentProfile = newProfile;
        });
      }
    }
  }

  void _onProfileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          onBack: () => Navigator.pop(context),
          onMicTap: widget.onMicTap,
          onMicLongPress: widget.onMicLongPress,
          micState: widget.micState,
          initialProfile: _currentProfile,
          onProfileChanged: (newProfile) {
            // Update global profile notifier
            profileNotifier.updateProfile(newProfile);
            widget.onProfileChanged?.call(newProfile);
          },
        ),
      ),
    );
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
                    label: 'Scene Describe',
                    sublabel: 'Describe what\nyou see',
                    icon: EyerisIcons.identify(size: 36),
                    semanticsLabel: 'Scene Describe. Describe what you see.',
                    semanticsHint: 'Double tap to open Scene Describe screen.',
                    onTap: widget.onNavigateTap,
                  ),
                  _buildCard(
                    label: 'Color Detect',
                    sublabel: 'Identify\ncolors',
                    icon: EyerisIcons.colorDetect(size: 36),
                    semanticsLabel: 'Color Detect. Identify colors.',
                    semanticsHint: 'Double tap to open Color Detect screen.',
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
          rightElement: profile.ProfileAvatar(onTap: _onProfileTap),
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
