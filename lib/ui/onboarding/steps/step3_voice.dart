import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

// ─────────────────────────────────────────────
// ONBOARDING STEP 3 — VOICE SETUP
//
// Two parts:
//   1. Mic test (visual only — no real recording
//      until Phase 5 wires audio).
//   2. Reading speed selector (Slow / Normal / Fast).
//
// Mic test flow:
//   idle  → user taps → simulates 2-second listen →
//   shows YES / NO prompt → user picks → resets or
//   marks as tested.
// ─────────────────────────────────────────────

enum _MicTestState { idle, listening, prompt, done }

class Step3Voice extends StatefulWidget {
  /// Currently selected speed: 'slow' | 'normal' | 'fast'
  final String voiceSpeed;
  final ValueChanged<String> onSpeedChanged;

  const Step3Voice({
    super.key,
    required this.voiceSpeed,
    required this.onSpeedChanged,
  });

  @override
  State<Step3Voice> createState() => _Step3VoiceState();
}

class _Step3VoiceState extends State<Step3Voice>
    with SingleTickerProviderStateMixin {
  _MicTestState _micState = _MicTestState.idle;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _startMicTest() async {
    setState(() => _micState = _MicTestState.listening);
    _pulseCtrl.repeat(reverse: true);
    HapticFeedback.mediumImpact();

    SemanticsService.announce(
      'Listening. Speak now.',
      TextDirection.ltr,
    );

    // Simulate 2-second recording window
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    setState(() => _micState = _MicTestState.prompt);
    SemanticsService.announce(
      'Did you hear your voice played back? '
      'Double tap Yes or No.',
      TextDirection.ltr,
    );
  }

  void _handleYes() {
    HapticFeedback.lightImpact();
    setState(() => _micState = _MicTestState.done);
    SemanticsService.announce(
      'Microphone test passed.',
      TextDirection.ltr,
    );
  }

  void _handleNo() {
    HapticFeedback.lightImpact();
    setState(() => _micState = _MicTestState.idle);
    SemanticsService.announce(
      'Microphone test failed. Tap to try again.',
      TextDirection.ltr,
    );
  }

  Color get _micBg {
    switch (_micState) {
      case _MicTestState.listening:
        return EyerisColors.white;
      case _MicTestState.done:
        return const Color(0xFF1A6B2A); // muted green — tested OK
      default:
        return EyerisColors.primary;
    }
  }

  String get _micA11yLabel {
    switch (_micState) {
      case _MicTestState.idle:
        return 'Test microphone. Double tap to begin.';
      case _MicTestState.listening:
        return 'Listening. Speak now.';
      case _MicTestState.prompt:
        return 'Microphone test complete.';
      case _MicTestState.done:
        return 'Microphone test passed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SET UP YOUR VOICE',
          style: EyerisText.mono(
            size: 22,
            letterSpacing: 0.10,
            color: EyerisColors.textPrimary,
          ),
        ),

        const SizedBox(height: EyerisSpacing.md),

        Text(
          'Test the microphone and choose your preferred '
          'reading voice.',
          style: EyerisText.mono(
            size: 14,
            weight: FontWeight.w400,
            letterSpacing: 0.02,
            color: EyerisColors.textMuted,
            height: 1.8,
          ),
        ),

        const SizedBox(height: EyerisSpacing.xl),

        // ── Mic test area
        Center(
          child: Column(
            children: [
              // Mic button
              Semantics(
                label: _micA11yLabel,
                button: _micState == _MicTestState.idle,
                child: GestureDetector(
                  onTap: _micState == _MicTestState.idle
                      ? _startMicTest
                      : null,
                  child: AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: _micState == _MicTestState.listening
                          ? _pulseAnim.value
                          : 1.0,
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _micBg,
                        shape: BoxShape.circle,
                        border: _micState == _MicTestState.listening
                            ? Border.all(
                                color: EyerisColors.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: EyerisIcons.mic(
                          size: 36,
                          color: EyerisColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: EyerisSpacing.md),

              // State label below button
              ExcludeSemantics(
                child: Text(
                  _micStateLabel,
                  style: EyerisText.mono(
                    size: 11,
                    weight: FontWeight.w400,
                    letterSpacing: 0.08,
                    color: EyerisColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // YES / NO prompt
              if (_micState == _MicTestState.prompt) ...[
                const SizedBox(height: EyerisSpacing.base),
                _YesNoRow(onYes: _handleYes, onNo: _handleNo),
              ],
            ],
          ),
        ),

        const SizedBox(height: EyerisSpacing.xxl),

        // ── Speed selector
        ExcludeSemantics(
          child: Text(
            'READING VOICE',
            style: EyerisText.sectionLabel,
          ),
        ),

        const SizedBox(height: EyerisSpacing.sm),

        _SpeedSelector(
          selected: widget.voiceSpeed,
          onChanged: widget.onSpeedChanged,
        ),
      ],
    );
  }

  String get _micStateLabel {
    switch (_micState) {
      case _MicTestState.idle:
        return 'TAP TO TEST MICROPHONE';
      case _MicTestState.listening:
        return 'LISTENING…';
      case _MicTestState.prompt:
        return 'DID YOU HEAR YOUR VOICE?';
      case _MicTestState.done:
        return 'MICROPHONE READY ✓';
    }
  }
}

// ─────────────────────────────────────────────
// YES / NO ROW — shown after mic test
// ─────────────────────────────────────────────

class _YesNoRow extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _YesNoRow({required this.onYes, required this.onNo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _YesNoButton(
            label: 'YES',
            semanticsLabel: 'Yes. Microphone test passed.',
            onTap: onYes,
            highlight: true,
          ),
        ),
        const SizedBox(width: EyerisSpacing.sm),
        Expanded(
          child: _YesNoButton(
            label: 'NO',
            semanticsLabel: 'No. Try the microphone test again.',
            onTap: onNo,
            highlight: false,
          ),
        ),
      ],
    );
  }
}

class _YesNoButton extends StatefulWidget {
  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;
  final bool highlight;

  const _YesNoButton({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
    required this.highlight,
  });

  @override
  State<_YesNoButton> createState() => _YesNoButtonState();
}

class _YesNoButtonState extends State<_YesNoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 56,
          decoration: BoxDecoration(
            color: _pressed || widget.highlight
                ? const Color(0xFF1A1700)
                : EyerisColors.surface,
            border: Border.all(
              color: _pressed || widget.highlight
                  ? EyerisColors.borderFocus
                  : EyerisColors.border,
              width: EyerisBorders.card,
            ),
            borderRadius: BorderRadius.circular(EyerisRadii.card),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: EyerisText.mono(
                size: 13,
                color: widget.highlight
                    ? EyerisColors.primary
                    : EyerisColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SPEED SELECTOR — three horizontal pill buttons
// ─────────────────────────────────────────────

class _SpeedSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const _speeds = [
    ('slow',   'SLOW'),
    ('normal', 'NORMAL'),
    ('fast',   'FAST'),
  ];

  const _SpeedSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_speeds.length, (i) {
        final (id, label) = _speeds[i];
        final isSelected = selected == id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i < _speeds.length - 1 ? EyerisSpacing.sm : 0,
            ),
            child: Semantics(
              label: '$label reading speed. '
                  '${isSelected ? 'Selected.' : 'Double tap to select.'}',
              button: true,
              checked: isSelected,
              child: GestureDetector(
                onTap: () => onChanged(id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1700)
                        : EyerisColors.surface,
                    border: Border.all(
                      color: isSelected
                          ? EyerisColors.borderFocus
                          : EyerisColors.border,
                      width: EyerisBorders.card,
                    ),
                    borderRadius: BorderRadius.circular(EyerisRadii.card),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: EyerisText.mono(
                        size: 11,
                        letterSpacing: 0.08,
                        color: isSelected
                            ? EyerisColors.primary
                            : EyerisColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
