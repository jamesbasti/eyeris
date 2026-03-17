// lib/widgets/sos_countdown_modal.dart
//
// Countdown modal for emergency SOS activation.
// Shows 3-second countdown with cancel option.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/services/haptic_feedback_service.dart';

/// Shows the SOS countdown modal.
/// Returns `true` if countdown completed, `false` if cancelled.
Future<bool?> showSOSCountdownModal(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: const Color(0xEB000000), // 92% black
    barrierDismissible: false,
    builder: (_) => const _SOSCountdownContent(),
  );
}

class _SOSCountdownContent extends StatefulWidget {
  const _SOSCountdownContent();

  @override
  State<_SOSCountdownContent> createState() => _SOSCountdownContentState();
}

class _SOSCountdownContentState extends State<_SOSCountdownContent>
    with SingleTickerProviderStateMixin {
  int _countdown = 3;
  Timer? _countdownTimer;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Announce modal
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          'Emergency SOS countdown. 3 seconds. Tap cancel to abort.',
          TextDirection.ltr,
        );
      }
    });

    // Start countdown
    _startCountdown();
  }

  void _startCountdown() {
    // Warning haptic
    HapticFeedbackService.instance.trigger(HapticPattern.warning);

    // Start progress animation
    _progressController.forward();

    // Start countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown--;
      });

      // Haptic tick
      HapticFeedbackService.instance.trigger(HapticPattern.medium);

      // Announce countdown
      if (context.mounted) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          '$_countdown',
          TextDirection.ltr,
        );
      }

      if (_countdown <= 0) {
        timer.cancel();
        _onCountdownComplete();
      }
    });
  }

  void _onCountdownComplete() {
    // Heavy haptic
    HapticFeedbackService.instance.trigger(HapticPattern.heavy);

    if (context.mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Countdown complete. Opening confirmation.',
        TextDirection.ltr,
      );
    }

    // Close with success
    Navigator.of(context).pop(true);
  }

  void _onCancel() {
    // Error haptic
    HapticFeedbackService.instance.trigger(HapticPattern.error);

    if (context.mounted) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        'Emergency SOS cancelled.',
        TextDirection.ltr,
      );
    }

    Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.all(EyerisSpacing.xxl),
              decoration: BoxDecoration(
                color: EyerisColors.surface,
                border: Border.all(
                  color: EyerisColors.danger,
                  width: EyerisBorders.header,
                ),
                borderRadius: BorderRadius.circular(EyerisRadii.card),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Countdown title
                  Semantics(
                    header: true,
                    child: Text(
                      'EMERGENCY SOS',
                      style: EyerisText.mono(
                        size: 18,
                        letterSpacing: 0.12,
                        color: EyerisColors.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: EyerisSpacing.xl),

                  // Circular countdown
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Progress ring
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return CircularProgressIndicator(
                              value: _progressAnimation.value,
                              strokeWidth: 8,
                              backgroundColor: EyerisColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                EyerisColors.danger,
                              ),
                            );
                          },
                        ),

                        // Countdown number
                        ExcludeSemantics(
                          child: Text(
                            '$_countdown',
                            style: TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              color: EyerisColors.danger,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: EyerisSpacing.xl),

                  // Warning text
                  Text(
                    'Activating emergency broadcast...',
                    style: EyerisText.mono(
                      size: 14,
                      weight: FontWeight.w400,
                      color: EyerisColors.textPrimary,
                      letterSpacing: 0.02,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: EyerisSpacing.xxl),

                  // CANCEL button
                  _CancelButton(onTap: _onCancel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CancelButton({required this.onTap});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cancel. Stop emergency SOS activation.',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: _pressed
                ? EyerisColors.danger.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(EyerisRadii.large),
            border: Border.all(
              color: EyerisColors.danger,
              width: EyerisBorders.thick,
            ),
          ),
          child: Center(
            child: Text(
              'CANCEL',
              style: EyerisText.mono(
                size: 16,
                letterSpacing: 0.10,
                color: EyerisColors.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
