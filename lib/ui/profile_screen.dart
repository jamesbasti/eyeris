import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/mic_bar.dart';
import 'package:eyeris/widgets/screen_header.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/ui/onboarding/onboarding_screen.dart';

// ─────────────────────────────────────────────
// PROFILE SCREEN
//
// Shows onboarding profile settings and allows editing
// Layout:
//   AppStatusBar
//   ScreenHeader "PROFILE" + back button
//   ScrollView:
//     Section "VISION"
//       ActionRow: Vision Type (show selected types)
//       ActionRow: Change Vision Settings
//     Section "INTERACTION"
//       ActionRow: Interaction Mode (touch/voice)
//       ActionRow: Change Interaction
//     Section "VOICE"
//       ActionRow: Voice Speed (slow/normal/fast)
//       ActionRow: Change Voice Settings
//   MicBar
// ─────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onMicTap;
  final VoidCallback? onMicLongPress;
  final MicBarState micState;
  final OnboardingProfile? initialProfile;
  final ValueChanged<OnboardingProfile>? onProfileChanged;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onMicTap,
    this.onMicLongPress,
    this.micState = MicBarState.idle,
    this.initialProfile,
    this.onProfileChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late OnboardingProfile _profile;

  @override
  void initState() {
    super.initState();
    // Use provided profile or create default
    _profile = widget.initialProfile ?? const OnboardingProfile(
      visionTypes: {'low-vision'},
      interactionMode: 'touch',
      voiceSpeed: 'normal',
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Profile screen. View and change your accessibility settings.',
          TextDirection.ltr,
        );
      }
    });
  }

  String _getVisionDisplayText() {
    if (_profile.visionTypes.isEmpty) return 'Not set';
    
    final List<String> displayNames = [];
    for (final type in _profile.visionTypes) {
      switch (type) {
        case 'low-vision':
          displayNames.add('Low Vision');
          break;
        case 'blind':
          displayNames.add('Blind');
          break;
        case 'color-blind':
          displayNames.add('Color Blind');
          break;
        default:
          displayNames.add(type);
      }
    }
    
    return displayNames.join(', ');
  }

  String _getInteractionDisplayText() {
    switch (_profile.interactionMode) {
      case 'touch':
        return 'Touch & Gestures';
      case 'voice':
        return 'Voice Control';
      default:
        return _profile.interactionMode;
    }
  }

  String _getVoiceSpeedDisplayText() {
    switch (_profile.voiceSpeed) {
      case 'slow':
        return 'Slow';
      case 'normal':
        return 'Normal';
      case 'fast':
        return 'Fast';
      default:
        return _profile.voiceSpeed;
    }
  }

  void _showVisionOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vision Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Low Vision'),
              value: _profile.visionTypes.contains('low-vision'),
              onChanged: (value) {
                Navigator.pop(context);
                _updateVisionType('low-vision', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Blind'),
              value: _profile.visionTypes.contains('blind'),
              onChanged: (value) {
                Navigator.pop(context);
                _updateVisionType('blind', value ?? false);
              },
            ),
            CheckboxListTile(
              title: const Text('Color Blind'),
              value: _profile.visionTypes.contains('color-blind'),
              onChanged: (value) {
                Navigator.pop(context);
                _updateVisionType('color-blind', value ?? false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showInteractionOptions() {
    String selectedMode = _profile.interactionMode;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Interaction Mode'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Touch & Gestures'),
                  trailing: selectedMode == 'touch' 
                    ? const Icon(Icons.radio_button_checked, color: EyerisColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      selectedMode = 'touch';
                    });
                  },
                ),
                ListTile(
                  title: const Text('Voice Control'),
                  trailing: selectedMode == 'voice' 
                    ? const Icon(Icons.radio_button_checked, color: EyerisColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      selectedMode = 'voice';
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateInteractionMode(selectedMode);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showVoiceSpeedOptions() {
    String selectedSpeed = _profile.voiceSpeed;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Speed'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Slow'),
                  trailing: selectedSpeed == 'slow' 
                    ? const Icon(Icons.radio_button_checked, color: EyerisColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      selectedSpeed = 'slow';
                    });
                  },
                ),
                ListTile(
                  title: const Text('Normal'),
                  trailing: selectedSpeed == 'normal' 
                    ? const Icon(Icons.radio_button_checked, color: EyerisColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      selectedSpeed = 'normal';
                    });
                  },
                ),
                ListTile(
                  title: const Text('Fast'),
                  trailing: selectedSpeed == 'fast' 
                    ? const Icon(Icons.radio_button_checked, color: EyerisColors.primary)
                    : const Icon(Icons.radio_button_unchecked),
                  onTap: () {
                    setState(() {
                      selectedSpeed = 'fast';
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateVoiceSpeed(selectedSpeed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateVisionType(String type, bool selected) {
    setState(() {
      final newVisionTypes = Set<String>.from(_profile.visionTypes);
      if (selected) {
        newVisionTypes.add(type);
      } else {
        newVisionTypes.remove(type);
      }
      _profile = OnboardingProfile(
        visionTypes: newVisionTypes,
        interactionMode: _profile.interactionMode,
        voiceSpeed: _profile.voiceSpeed,
      );
      // Notify parent of change
      widget.onProfileChanged?.call(_profile);
    });
  }

  void _updateInteractionMode(String mode) {
    setState(() {
      _profile = OnboardingProfile(
        visionTypes: _profile.visionTypes,
        interactionMode: mode,
        voiceSpeed: _profile.voiceSpeed,
      );
      // Notify parent of change
      widget.onProfileChanged?.call(_profile);
    });
  }

  void _updateVoiceSpeed(String speed) {
    setState(() {
      _profile = OnboardingProfile(
        visionTypes: _profile.visionTypes,
        interactionMode: _profile.interactionMode,
        voiceSpeed: speed,
      );
      // Notify parent of change
      widget.onProfileChanged?.call(_profile);
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
            child: ScreenHeader(
              title: 'Profile',
              onBack: widget.onBack,
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(EyerisSpacing.md2),
              children: [
                ActionRow(
                  label: 'Vision Type',
                  sublabel: _getVisionDisplayText(),
                  icon: EyerisIcons.read(size: 28),
                  onPress: _showVisionOptions,
                  semanticsLabel: 'Vision type: ${_getVisionDisplayText()}',
                  semanticsHint: 'Double tap to change vision settings',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Interaction Mode',
                  sublabel: _getInteractionDisplayText(),
                  icon: EyerisIcons.communicate(size: 28),
                  onPress: _showInteractionOptions,
                  semanticsLabel: 'Interaction mode: ${_getInteractionDisplayText()}',
                  semanticsHint: 'Double tap to change interaction settings',
                ),
                const SizedBox(height: EyerisSpacing.sm),

                ActionRow(
                  label: 'Voice Speed',
                  sublabel: _getVoiceSpeedDisplayText(),
                  icon: EyerisIcons.voice(size: 28),
                  onPress: _showVoiceSpeedOptions,
                  semanticsLabel: 'Voice speed: ${_getVoiceSpeedDisplayText()}',
                  semanticsHint: 'Double tap to change voice speed',
                ),
              ],
            ),
          ),

          MicBar(
            contextLabel: "Say 'Change Settings'",
            contextHint: 'Or tap options above',
            onPress: widget.onMicTap,
            onLongPress: widget.onMicLongPress,
            state: widget.micState,
          ),
        ],
      ),
    );
  }
}
