import 'package:flutter/material.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// ONBOARDING STEP 1 — VISION PROFILE
//
// Multi-select: user picks one or more vision types.
// At least one must be selected to continue —
// validation is handled by OnboardingScreen which
// reads [selected] before enabling the CONTINUE button.
// ─────────────────────────────────────────────

/// Immutable option descriptor.
class VisionOption {
  final String id;
  final String label;
  final String sublabel;
  final Widget icon;

  const VisionOption({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

class Step1Vision extends StatelessWidget {
  /// Currently selected option IDs.
  final Set<String> selected;

  /// Called whenever the selection changes.
  final ValueChanged<Set<String>> onChanged;

  Step1Vision({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  // Options defined once — stable references.
  final List<VisionOption> _options = [
    VisionOption(
      id: 'blind',
      label: 'TOTAL BLINDNESS',
      sublabel: 'I use a screen reader',
      icon: EyerisIcons.person(size: 22),
    ),
    VisionOption(
      id: 'low_vision',
      label: 'LOW VISION',
      sublabel: 'I can see partially or with magnification',
      icon: EyerisIcons.identify(size: 22),
    ),
    VisionOption(
      id: 'color_blind',
      label: 'COLOR BLINDNESS',
      sublabel: 'I have difficulty distinguishing colors',
      icon: EyerisIcons.colorDetect(size: 22),
    ),
    VisionOption(
      id: 'other',
      label: 'OTHER',
      sublabel: 'Prefer not to say',
      icon: EyerisIcons.communicate(size: 22),
    ),
  ];

  void _toggle(String id) {
    final next = Set<String>.from(selected);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW DO YOU SEE?',
          style: EyerisText.mono(
            size: 22,
            letterSpacing: 0.10,
            color: EyerisColors.textPrimary,
          ),
        ),

        const SizedBox(height: EyerisSpacing.md),

        Text(
          'This helps us adjust contrast, text size, and '
          'color settings for you.',
          style: EyerisText.mono(
            size: 14,
            weight: FontWeight.w400,
            letterSpacing: 0.02,
            color: EyerisColors.textMuted,
            height: 1.8,
          ),
        ),

        const SizedBox(height: EyerisSpacing.xl),

        // Selection cards
        ...List.generate(_options.length, (i) {
          final opt = _options[i];
          final isSelected = selected.contains(opt.id);
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _options.length - 1 ? EyerisSpacing.sm : 0,
            ),
            child: _SelectCard(
              label: opt.label,
              sublabel: opt.sublabel,
              icon: opt.icon,
              selected: isSelected,
              multiSelect: true,
              semanticsLabel:
                  '${opt.label}. ${opt.sublabel}. '
                  '${isSelected ? 'Selected' : 'Not selected'}.',
              onTap: () => _toggle(opt.id),
            ),
          );
        }),

        // Inline validation message — shown when nothing is selected
        // and the parent has attempted to advance (parent sets
        // showValidation). Since OnboardingScreen controls the button,
        // we just always show the hint when selection is empty — it
        // appears only after the user has had a chance to interact.
        if (selected.isEmpty) ...[
          const SizedBox(height: EyerisSpacing.md),
          Text(
            'Please select at least one option to continue.',
            style: EyerisText.mono(
              size: 12,
              weight: FontWeight.w400,
              color: EyerisColors.danger,
              letterSpacing: 0.03,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// SHARED SELECT CARD
// Used by Step1 (multi-select / checkbox) and
// Step2 (single-select / radio). Exported so
// step2 can import it directly.
// ─────────────────────────────────────────────

class SelectCard extends StatefulWidget {
  final String label;
  final String sublabel;
  final Widget icon;
  final bool selected;

  /// true  = checkbox semantics (multi-select)
  /// false = radio semantics (single-select)
  final bool multiSelect;

  final String semanticsLabel;
  final VoidCallback onTap;

  const SelectCard({
    super.key,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.selected,
    required this.multiSelect,
    required this.semanticsLabel,
    required this.onTap,
  });

  @override
  State<SelectCard> createState() => _SelectCardState();
}

class _SelectCardState extends State<SelectCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      checked: widget.selected,
      button: true,
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(
            horizontal: 18.0,
            vertical: EyerisSpacing.base,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF1A1700)
                : EyerisColors.surface,
            border: Border.all(
              color: widget.selected || _pressed
                  ? EyerisColors.borderFocus
                  : EyerisColors.border,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon box
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: EyerisColors.black,
                  border: Border.all(
                    color: EyerisColors.primary,
                    width: EyerisBorders.thick,
                  ),
                  borderRadius: BorderRadius.circular(EyerisRadii.large),
                ),
                child: Center(child: widget.icon),
              ),

              const SizedBox(width: 14),

              // Labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: EyerisText.mono(
                        size: 14,
                        letterSpacing: 0.06,
                        color: EyerisColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.sublabel,
                      style: EyerisText.mono(
                        size: 11,
                        weight: FontWeight.w400,
                        letterSpacing: 0.03,
                        color: EyerisColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: EyerisSpacing.sm),

              // Check / radio indicator
              ExcludeSemantics(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.selected
                        ? EyerisColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: widget.selected
                          ? EyerisColors.primary
                          : EyerisColors.border,
                      width: EyerisBorders.thick,
                    ),
                  ),
                  child: widget.selected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: EyerisColors.black,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// SelectCard is exported from this file and imported by Step2 and Step3.
