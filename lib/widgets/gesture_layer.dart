import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// GESTURE LAYER
//
// Wraps the scrollable content area of every screen
// (between ScreenHeader and MicBar) and interprets
// global swipe and long-press shortcuts.
//
// Gesture map:
//   2-finger swipe LEFT  → onBack   (go to previous screen)
//   2-finger swipe RIGHT → onVoice  (activate mic / voice input)
//   Long press anywhere  → announce screen name + available options
//
// Screen reader safety:
//   When TalkBack (Android) or VoiceOver (iOS) is active,
//   GestureLayer renders children directly with NO gesture
//   interception. Screen readers own all gestures in that
//   mode — custom overrides would break navigation.
//
// Detection strategy (no external packages required):
//   Listener counts active pointers. When ≥2 pointers are
//   down during a horizontal pan, it is treated as a 2-finger
//   swipe. Velocity + distance thresholds prevent accidental
//   triggers from scrolling or incidental two-finger contact.
//
// Thresholds:
//   minSwipeDistance : 80 logical pixels
//   minSwipeVelocity : 300 logical pixels / second
//
// Haptics:
//   Back gesture  → HapticFeedback.lightImpact
//   Voice gesture → HapticFeedback.mediumImpact
//   Long press    → HapticFeedback.heavyImpact
// ─────────────────────────────────────────────

class GestureLayer extends StatefulWidget {
  /// Called when the user performs a 2-finger swipe left.
  /// Typically `() => Navigator.pop(context)`.
  /// If null the gesture is silently ignored.
  final VoidCallback? onBack;

  /// Called when the user performs a 2-finger swipe right.
  /// Typically triggers MicBar voice input.
  /// If null the gesture is silently ignored.
  final VoidCallback? onVoice;

  /// Screen name announced on long press.
  /// E.g. "Read screen".
  final String screenName;

  /// Options announced on long press after screen name.
  /// E.g. ["Point and Read", "Scan Document", "Reading Speed"].
  final List<String> options;

  /// Content to wrap. Receives the full available space.
  final Widget child;

  // Test-only parameter to force screen reader state
  final bool forceScreenReaderActive;

  const GestureLayer({
    super.key,
    required this.onBack,
    required this.onVoice,
    required this.screenName,
    required this.options,
    required this.child,
    this.forceScreenReaderActive = false,
  });

  @override
  State<GestureLayer> createState() => _GestureLayerState();
}

class _GestureLayerState extends State<GestureLayer> {
  // ── Pointer tracking
  int _activePointers = 0;
  Offset? _twoFingerStart;
  Offset? _twoFingerCurrent;
  DateTime? _twoFingerStartTime;

  // ── Thresholds
  static const double _minDistance = 80.0;
  static const double _minVelocity = 300.0; // logical px / second

  // ── Screen reader flag (read once per build cycle)
  bool _screenReaderActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // accessibleNavigation is true when TalkBack / VoiceOver is enabled.
    // For Flutter 3.41.3, we need to check what the actual API is
    try {
      _screenReaderActive = MediaQuery.accessibleNavigationOf(context);
    } catch (e) {
      // Fallback for testing - check if we're in test environment
      _screenReaderActive = false;
    }
  }

  // ── Pointer event handlers

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    // Record start position when the second finger touches down.
    if (_activePointers == 2) {
      _twoFingerStart = event.position;
      _twoFingerCurrent = event.position;
      _twoFingerStartTime = DateTime.now();
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activePointers >= 2) {
      _twoFingerCurrent = event.position;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_activePointers >= 2 &&
        _twoFingerStart != null &&
        _twoFingerCurrent != null &&
        _twoFingerStartTime != null) {
      _evaluateSwipe(
        _twoFingerStart!,
        _twoFingerCurrent!,
        _twoFingerStartTime!,
      );
    }
    _activePointers = (_activePointers - 1).clamp(0, 20);
    if (_activePointers == 0) {
      _resetTwoFingerState();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = (_activePointers - 1).clamp(0, 20);
    if (_activePointers == 0) _resetTwoFingerState();
  }

  void _resetTwoFingerState() {
    _twoFingerStart = null;
    _twoFingerCurrent = null;
    _twoFingerStartTime = null;
  }

  // ── Swipe evaluation

  void _evaluateSwipe(
    Offset start,
    Offset end,
    DateTime startTime,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = dx.abs();

    // Must be primarily horizontal (dx dominates dy by 2:1)
    if (dx.abs() < dy.abs() * 2) return;

    // Must meet distance threshold
    if (distance < _minDistance) return;

    // Must meet velocity threshold
    final elapsedSeconds =
        DateTime.now().difference(startTime).inMilliseconds / 1000.0;
    if (elapsedSeconds <= 0) return;
    final velocity = distance / elapsedSeconds;
    if (velocity < _minVelocity) return;

    if (dx < 0) {
      _triggerBack();
    } else {
      _triggerVoice();
    }
  }

  // ── Gesture actions

  void _triggerBack() {
    if (widget.onBack == null) return;
    HapticFeedback.lightImpact();
    _sendAnnouncement('Going back.');
    widget.onBack!();
  }

  void _triggerVoice() {
    if (widget.onVoice == null) return;
    HapticFeedback.mediumImpact();
    _sendAnnouncement('Voice input activated.');
    widget.onVoice!();
  }

  void _triggerLongPressAnnounce() {
    HapticFeedback.heavyImpact();
    final optionsList = widget.options.join(', ');
    final message = 'You are on ${widget.screenName}. '
        'Options: $optionsList.';
    _sendAnnouncement(message);
  }

  void _sendAnnouncement(String message) {
    if (!mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  // ── Build

  @override
  Widget build(BuildContext context) {
    // Update screen reader flag on each build in case it changed.
    // Use test parameter if provided, otherwise try to detect
    if (widget.forceScreenReaderActive) {
      _screenReaderActive = true;
    } else {
      try {
        _screenReaderActive = MediaQuery.accessibleNavigationOf(context);
      } catch (e) {
        // Fallback for testing - check if we're in test environment
        _screenReaderActive = false;
      }
    }

    // When screen reader is active, pass through with zero interception.
    // TalkBack / VoiceOver own all gestures — never override them.
    if (_screenReaderActive) {
      return widget.child;
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      // HitTestBehavior.translucent lets the Listener receive pointer events
      // without blocking the child's own gesture recognisers (scroll, tap, etc).
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        // Long press on the content area announces screen + options.
        onLongPress: _triggerLongPressAnnounce,
        // Do not consume other gestures — child handles its own taps/scrolls.
        behavior: HitTestBehavior.translucent,
        child: widget.child,
      ),
    );
  }
}
