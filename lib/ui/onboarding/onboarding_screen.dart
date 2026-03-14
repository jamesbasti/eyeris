import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/ui/onboarding/steps/step1_vision.dart';
import 'package:eyeris/ui/onboarding/steps/step2_interaction.dart';
import 'package:eyeris/ui/onboarding/steps/step3_voice.dart';

// ─────────────────────────────────────────────
// ONBOARDING PROFILE
// Collected across the 3 steps.
// Passed to [onComplete] when the user finishes.
// Persistence (AsyncStorage equivalent via
// shared_preferences) is wired in Phase 5.
// ─────────────────────────────────────────────

class OnboardingProfile {
  final Set<String> visionTypes;
  final String interactionMode;
  final String voiceSpeed;

  const OnboardingProfile({
    required this.visionTypes,
    required this.interactionMode,
    required this.voiceSpeed,
  });

  @override
  String toString() =>
      'OnboardingProfile(vision: $visionTypes, '
      'interaction: $interactionMode, speed: $voiceSpeed)';
}

// ─────────────────────────────────────────────
// ONBOARDING SCREEN
//
// Layout (top → bottom):
//   SafeArea top
//   Progress bar (3 segments, 4px)
//   Optional back button row
//   Scrollable step content
//   CONTINUE / START button (80px)
//   SafeArea bottom
//
// Steps:
//   0 — Vision profile (multi-select, must pick ≥1)
//   1 — Interaction preference (single-select)
//   2 — Voice setup (mic test + speed)
// ─────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  /// Called when the user completes step 3.
  /// Phase 5 will persist [profile] to shared_preferences
  /// and navigate to HomeScreen.
  final ValueChanged<OnboardingProfile> onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 3;

  int _step = 0;

  // Step 1 state
  Set<String> _visionTypes = {};

  // Step 2 state — pre-select 'touch' so CONTINUE is enabled immediately
  String _interactionMode = 'touch';

  // Step 3 state
  String _voiceSpeed = 'normal';

  // Controls whether the validation message on step 1 is visible.
  // True after the user taps CONTINUE with nothing selected.
  bool _showValidationError = false;

  bool get _canContinue {
    if (_step == 0) return _visionTypes.isNotEmpty;
    return true; // steps 1 and 2 always have a value
  }

  void _onBack() {
    if (_step > 0) setState(() => _step--);
  }

  void _onContinue() {
    if (!_canContinue) {
      setState(() => _showValidationError = true);
      SemanticsService.announce(
        'Please select at least one option to continue.',
        TextDirection.ltr,
      );
      return;
    }

    setState(() => _showValidationError = false);

    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      SemanticsService.announce(
        _stepAnnouncement(_step),
        TextDirection.ltr,
      );
    } else {
      // Step 3 complete — hand profile to parent
      widget.onComplete(
        OnboardingProfile(
          visionTypes:     _visionTypes,
          interactionMode: _interactionMode,
          voiceSpeed:      _voiceSpeed,
        ),
      );
      SemanticsService.announce(
        'Setup complete. Welcome to Eyeris.',
        TextDirection.ltr,
      );
    }
  }

  String _stepAnnouncement(int step) {
    switch (step) {
      case 1:
        return 'Step 2 of 3. How do you interact?';
      case 2:
        return 'Step 3 of 3. Set up your voice.';
      default:
        return 'Step 1 of 3. How do you see?';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: EyerisColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Progress bar
            _ProgressBar(currentStep: _step, totalSteps: _totalSteps),

            // ── Back button row (hidden on step 0)
            if (_step > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: EyerisSpacing.base,
                    top: EyerisSpacing.md,
                    bottom: EyerisSpacing.xs,
                  ),
                  child: Semantics(
                    label: 'Go back to previous step',
                    button: true,
                    child: GestureDetector(
                      onTap: _onBack,
                      child: Container(
                        width: EyerisTouchTargets.backButton,
                        height: EyerisTouchTargets.backButton,
                        decoration: BoxDecoration(
                          color: EyerisColors.primary,
                          borderRadius:
                              BorderRadius.circular(EyerisRadii.small),
                        ),
                        child: Center(
                          child: Text(
                            '←',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: EyerisColors.black,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: EyerisSpacing.base),

            // ── Scrollable step content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: EyerisSpacing.base,
                ),
                child: _buildStep(),
              ),
            ),

            // ── CONTINUE / START button
            Padding(
              padding: EdgeInsets.fromLTRB(
                EyerisSpacing.base,
                EyerisSpacing.base,
                EyerisSpacing.base,
                EyerisSpacing.base + bottomPadding,
              ),
              child: _ContinueButton(
                label: _step == _totalSteps - 1
                    ? 'START USING EYERIS'
                    : 'CONTINUE',
                enabled: _canContinue,
                onTap: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return Step1Vision(
          selected: _visionTypes,
          onChanged: (v) {
            setState(() {
              _visionTypes = v;
              if (v.isNotEmpty) _showValidationError = false;
            });
          },
        );
      case 1:
        return Step2Interaction(
          selected: _interactionMode,
          onChanged: (v) => setState(() => _interactionMode = v),
        );
      case 2:
        return Step3Voice(
          voiceSpeed: _voiceSpeed,
          onSpeedChanged: (v) => setState(() => _voiceSpeed = v),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────
// PROGRESS BAR
// 3 horizontal segments. Yellow = complete or active,
// dark = upcoming. 4px height, no border-radius.
// ─────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          children: List.generate(totalSteps, (i) {
            final active = i <= currentStep;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 4,
                margin: EdgeInsets.only(
                  right: i < totalSteps - 1 ? 2.0 : 0,
                ),
                color: active ? EyerisColors.primary : EyerisColors.border,
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONTINUE BUTTON
// Full-width, 80px, yellow. Dims when disabled.
// ─────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        onTapDown:   widget.enabled ? (_) => setState(() => _pressed = true)  : null,
        onTapUp:     widget.enabled ? (_) { setState(() => _pressed = false); widget.onTap(); } : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false)  : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: widget.enabled ? 1.0 : 0.4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: _pressed
                  ? EyerisColors.primaryDim
                  : EyerisColors.primary,
              borderRadius: BorderRadius.circular(EyerisRadii.card),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: EyerisText.mono(
                  size: 15,
                  letterSpacing: 0.10,
                  color: EyerisColors.textOnPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
