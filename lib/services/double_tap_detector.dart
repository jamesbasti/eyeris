// lib/services/double_tap_detector.dart
//
// Service for detecting double-tap gestures with configurable timing.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Double-tap detection service
class DoubleTapDetector {
  final Duration tapWindow;
  final VoidCallback onDoubleTap;
  final VoidCallback? onFirstTap;
  
  DateTime? _lastTapTime;
  Timer? _resetTimer;
  
  DoubleTapDetector({
    this.tapWindow = const Duration(milliseconds: 500),
    required this.onDoubleTap,
    this.onFirstTap,
  });

  /// Register a tap event
  void registerTap() {
    final now = DateTime.now();
    
    if (_lastTapTime == null) {
      // First tap
      _lastTapTime = now;
      onFirstTap?.call();
      
      // Start reset timer
      _resetTimer?.cancel();
      _resetTimer = Timer(tapWindow, _reset);
      
      debugPrint('DoubleTapDetector: First tap registered');
    } else {
      // Check if within tap window
      final timeSinceLastTap = now.difference(_lastTapTime!);
      
      if (timeSinceLastTap <= tapWindow) {
        // Double tap detected!
        debugPrint('DoubleTapDetector: Double tap detected (${timeSinceLastTap.inMilliseconds}ms)');
        _reset();
        onDoubleTap();
      } else {
        // Too slow, treat as new first tap
        debugPrint('DoubleTapDetector: Tap too slow, resetting');
        _lastTapTime = now;
        onFirstTap?.call();
        
        _resetTimer?.cancel();
        _resetTimer = Timer(tapWindow, _reset);
      }
    }
  }

  /// Reset the detector state
  void _reset() {
    _lastTapTime = null;
    _resetTimer?.cancel();
    _resetTimer = null;
    debugPrint('DoubleTapDetector: State reset');
  }

  /// Manually reset (useful for cancellation)
  void reset() {
    _reset();
  }

  /// Clean up resources
  void dispose() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _lastTapTime = null;
  }
}
