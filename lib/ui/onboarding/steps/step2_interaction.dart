import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';
import 'package:eyeris/ui/onboarding/steps/step1_vision.dart'
    show SelectCard;

// ─────────────────────────────────────────────
// ONBOARDING STEP 2 — INTERACTION PREFERENCE
//
// Single-select: user picks exactly one mode.
// A value is always pre-selected ('touch') so
// the CONTINUE button is enabled immediately.
// ─────────────────────────────────────────────

class InteractionOption {
  final String id;
  final String label;
  final String sublabel;
  final Widget icon;

  const InteractionOption({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

class Step2Interaction extends StatelessWidget {
  /// Currently selected option ID.
  final String selected;

  /// Called with the newly selected ID.
  final ValueChanged<String> onChanged;

  Step2Interaction({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final List<InteractionOption> _options = [
    InteractionOption(
      id: 'touch',
      label: 'TOUCH',
      sublabel: 'Large tap targets, tap to activate',
      icon: EyerisIcons.identify(size: 22),
    ),
    InteractionOption(
      id: 'voice',
      label: 'VOICE FIRST',
      sublabel: 'Speak commands, minimal tapping',
      icon: EyerisIcons.voice(size: 22),
    ),
    InteractionOption(
      id: 'switch_access',
      label: 'SWITCH ACCESS',
      sublabel: 'I use an external switch device',
      icon: EyerisIcons.communicate(size: 22),
    ),
    InteractionOption(
      id: 'mixed',
      label: 'MIXED',
      sublabel: 'I use a combination of methods',
      icon: EyerisIcons.navigate(size: 22),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW DO YOU INTERACT?',
          style: EyerisText.mono(
            size: 22,
            letterSpacing: 0.10,
            color: EyerisColors.textPrimary,
          ),
        ),

        const SizedBox(height: EyerisSpacing.md),

        Text(
          "We'll tune gesture sensitivity and default "
          'input methods.',
          style: EyerisText.mono(
            size: 14,
            weight: FontWeight.w400,
            letterSpacing: 0.02,
            color: EyerisColors.textMuted,
            height: 1.8,
          ),
        ),

        const SizedBox(height: EyerisSpacing.xl),

        ...List.generate(_options.length, (i) {
          final opt = _options[i];
          final isSelected = selected == opt.id;
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _options.length - 1 ? EyerisSpacing.sm : 0,
            ),
            child: SelectCard(
              label: opt.label,
              sublabel: opt.sublabel,
              icon: opt.icon,
              selected: isSelected,
              multiSelect: false,
              semanticsLabel:
                  '${opt.label}. ${opt.sublabel}. '
                  '${isSelected ? 'Selected' : 'Not selected'}.',
              onTap: () => onChanged(opt.id),
            ),
          );
        }),
      ],
    );
  }
}
