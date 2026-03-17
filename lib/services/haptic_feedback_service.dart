// lib/services/haptic_feedback_service.dart
//
// Enhanced haptic feedback service with pattern support.

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Haptic feedback patterns
enum HapticPattern {
  light,      // First tap
  medium,     // Second tap, countdown tick
  heavy,      // Countdown complete
  success,    // SOS sent (3 light pulses)
  warning,    // Countdown started
  error,      // Action cancelled
}

/// Enhanced haptic feedback service
class HapticFeedbackService {
  HapticFeedbackService._();
  static final HapticFeedbackService instance = HapticFeedbackService._();

  /// Trigger a haptic pattern
  Future<void> trigger(HapticPattern pattern) async {
    try {
      switch (pattern) {
        case HapticPattern.light:
          await HapticFeedback.lightImpact();
          debugPrint('Haptic: light');
          break;
          
        case HapticPattern.medium:
          await HapticFeedback.mediumImpact();
          debugPrint('Haptic: medium');
          break;
          
        case HapticPattern.heavy:
          await HapticFeedback.heavyImpact();
          debugPrint('Haptic: heavy');
          break;
          
        case HapticPattern.success:
          // Success pattern: 3 light pulses
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          await HapticFeedback.lightImpact();
          debugPrint('Haptic: success pattern');
          break;
          
        case HapticPattern.warning:
          // Warning pattern: medium + light
          await HapticFeedback.mediumImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          await HapticFeedback.lightImpact();
          debugPrint('Haptic: warning pattern');
          break;
          
        case HapticPattern.error:
          // Error pattern: heavy vibration
          await HapticFeedback.heavyImpact();
          debugPrint('Haptic: error');
          break;
      }
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  /// Trigger a selection click (for UI feedback)
  Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
      debugPrint('Haptic: selection');
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  /// Trigger vibration (for alerts)
  Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
      debugPrint('Haptic: vibrate');
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }
}
