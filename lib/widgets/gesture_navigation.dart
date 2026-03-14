import 'package:flutter/material.dart';
import 'package:eyeris/widgets/gesture_layer.dart';

// ─────────────────────────────────────────────
// GESTURE NAVIGATION MIXIN
//
// Applied to StatelessWidget route wrappers in app.dart.
// Provides buildWithGestures() which wraps any Widget in
// a GestureLayer with the correct back/voice callbacks
// already bound to the Navigator.
//
// Usage in a route wrapper:
//
//   class _ReadRoute extends StatelessWidget
//       with GestureNavigation {
//
//     @override
//     Widget build(BuildContext context) {
//       return ReadScreen(
//         onBack: () => Navigator.pop(context),
//         ...
//       );
//     }
//   }
//
// Then in ReadScreen.build(), wrap the Expanded content:
//
//   Expanded(
//     child: GestureLayer(
//       onBack:     () => Navigator.pop(context),
//       onVoice:    () { /* mic */ },
//       screenName: 'Read screen',
//       options:    ['Point and Read', 'Scan Document',
//                    'Reading Speed', 'Voice and Language'],
//       child: ListView(...),
//     ),
//   ),
//
// Alternatively use GestureLayerConfig to pass config
// down from the route wrapper without rebuilding.
// ─────────────────────────────────────────────

/// Configuration object passed into screens so they can
/// construct a GestureLayer without knowing about Navigator.
class GestureLayerConfig {
  final VoidCallback? onBack;
  final VoidCallback? onVoice;
  final String screenName;
  final List<String> options;

  const GestureLayerConfig({
    this.onBack,
    this.onVoice,
    required this.screenName,
    required this.options,
  });

  /// Wraps [child] in a GestureLayer using this config.
  Widget wrap(Widget child) {
    return GestureLayer(
      onBack: onBack,
      onVoice: onVoice,
      screenName: screenName,
      options: options,
      child: child,
    );
  }
}
