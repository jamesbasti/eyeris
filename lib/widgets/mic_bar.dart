// lib/widgets/mic_bar.dart
// Persistent bottom voice entry bar. 88px height, 64px mic button, state visuals.

import 'package:flutter/material.dart';

import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

/// Mic bar state: idle, listening (pulse), processing (spinner).
enum MicBarState {
  idle,
  listening,
  processing,
}

/// Persistent bottom bar with mic button and context text. States: idle, listening, processing.
class MicBar extends StatefulWidget {
  const MicBar({
    super.key,
    required this.contextLabel,
    this.contextHint,
    required this.onPress,
    this.onLongPress,
    this.state = MicBarState.idle,
    this.accessibilityLabel,
  });

  final String contextLabel;
  final String? contextHint;
  final VoidCallback onPress;
  final VoidCallback? onLongPress;
  final MicBarState state;
  final String? accessibilityLabel;

  @override
  State<MicBar> createState() => _MicBarState();
}

class _MicBarState extends State<MicBar> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(MicBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == MicBarState.listening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != MicBarState.listening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String get _semanticLabel {
    if (widget.accessibilityLabel != null && widget.accessibilityLabel!.isNotEmpty) {
      return widget.accessibilityLabel!;
    }
    switch (widget.state) {
      case MicBarState.listening:
        return 'Listening. Speak your command.';
      case MicBarState.processing:
        return 'Processing your command.';
      case MicBarState.idle:
        return 'Activate voice command. Double tap to speak.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isListening = widget.state == MicBarState.listening;

    if (isListening && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: EyerisTheme.primary, width: EyerisTheme.borderFocus),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic button: 64×64 circle
          Semantics(
            label: _semanticLabel,
            hint: widget.onLongPress != null
                ? 'Long press for continuous listening.'
                : null,
            button: true,
            child: GestureDetector(
              onTap: widget.onPress,
              onLongPress: widget.onLongPress,
              child: _MicButton(
                state: widget.state,
                pulseAnimation: _pulseAnimation,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Context text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contextLabel.toUpperCase(),
                  style: typography(
                    size: 'sm',
                    weight: FontWeight.w700,
                    color: EyerisTheme.textPrimary,
                    letterSpacingKey: 'wide',
                  ).copyWith(letterSpacing: 12 * 0.08),
                ),
                if (widget.contextHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.contextHint!,
                    style: typography(
                      size: 'xs',
                      color: EyerisTheme.textMuted,
                    ).copyWith(height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({
    required this.state,
    required this.pulseAnimation,
  });

  final MicBarState state;
  final Animation<double> pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final bool isListening = state == MicBarState.listening;
    final bool isProcessing = state == MicBarState.processing;

    Color bgColor;
    if (isListening) {
      bgColor = EyerisTheme.white;
    } else if (isProcessing) {
      bgColor = EyerisTheme.primaryDim;
    } else {
      bgColor = EyerisTheme.primary;
    }

    Widget content = EyerisIcons.mic(
      size: 28,
      color: Colors.black,
    );
    if (isProcessing) {
      content = SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
    }

    if (isListening) {
      return AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          return Container(
            width: EyerisTheme.touchPrimaryButton,
            height: EyerisTheme.touchPrimaryButton,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(
                color: EyerisTheme.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: EyerisTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: (pulseAnimation.value - 1) * 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: content,
          );
        },
      );
    }

    return Container(
      width: EyerisTheme.touchPrimaryButton,
      height: EyerisTheme.touchPrimaryButton,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
