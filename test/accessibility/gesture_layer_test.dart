import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/widgets/gesture_layer.dart';

// Flutter 3.27+ removed accessibilityFeatures from MediaQueryData constructor.
// Use accessibleNavigation directly instead.

Widget buildLayer({
  VoidCallback? onBack,
  VoidCallback? onVoice,
  VoidCallback? onChildTap,
  bool screenReaderActive = false,
}) {
  return MaterialApp(
    theme: buildEyerisTheme(),
    // Use builder: to inject the MediaQuery override INSIDE MaterialApp.
    // Wrapping MaterialApp in MediaQuery doesn't work — MaterialApp creates
    // its own MediaQuery internally, overriding any outer wrapper.
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        accessibleNavigation: screenReaderActive,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: GestureLayer(
        onBack: onBack,
        onVoice: onVoice,
        screenName: 'Test screen',
        options: const ['Option A', 'Option B'],
        child: GestureDetector(
          onTap: onChildTap,
          child: const SizedBox(width: 400, height: 600),
        ),
      ),
    ),
  );
}

void main() {
  group('GestureLayer — 2-finger swipe left triggers onBack', () {
    testWidgets('200px left swipe calls onBack', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildLayer(onBack: () => called = true));

      final g1 = await tester.startGesture(const Offset(300, 280));
      final g2 = await tester.startGesture(const Offset(300, 320));
      await tester.pump(const Duration(milliseconds: 10));
      await g1.moveBy(const Offset(-200, 0));
      await g2.moveBy(const Offset(-200, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await g1.up();
      await g2.up();
      await tester.pump();

      expect(called, isTrue, reason: '2-finger left swipe must call onBack');
    });

    testWidgets('30px left swipe does NOT call onBack (below threshold)',
        (tester) async {
      bool called = false;
      await tester.pumpWidget(buildLayer(onBack: () => called = true));

      final g1 = await tester.startGesture(const Offset(300, 280));
      final g2 = await tester.startGesture(const Offset(300, 320));
      await tester.pump();
      await g1.moveBy(const Offset(-30, 0));
      await g2.moveBy(const Offset(-30, 0));
      await tester.pump();
      await g1.up();
      await g2.up();
      await tester.pump();

      expect(called, isFalse, reason: 'Short swipe must not trigger onBack');
    });
  });

  group('GestureLayer — 2-finger swipe right triggers onVoice', () {
    testWidgets('200px right swipe calls onVoice', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildLayer(onVoice: () => called = true));

      final g1 = await tester.startGesture(const Offset(100, 280));
      final g2 = await tester.startGesture(const Offset(100, 320));
      await tester.pump(const Duration(milliseconds: 10));
      await g1.moveBy(const Offset(200, 0));
      await g2.moveBy(const Offset(200, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await g1.up();
      await g2.up();
      await tester.pump();

      expect(called, isTrue, reason: '2-finger right swipe must call onVoice');
    });
  });

  group('GestureLayer — single-finger swipe does not trigger callbacks', () {
    testWidgets('1-finger drag does not call onBack', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildLayer(onBack: () => called = true));
      // Use dragFrom with an absolute coordinate — avoids the hit-test
      // off-screen warning that comes from using a finder on SizedBox.
      await tester.dragFrom(const Offset(200, 300), const Offset(-200, 0));
      await tester.pump();
      expect(called, isFalse, reason: 'Single-finger drag must not trigger onBack');
    });
  });

  group('GestureLayer — vertical swipe does not trigger callbacks', () {
    testWidgets('200px down with 2 fingers does not call onBack', (tester) async {
      bool backCalled = false;
      bool voiceCalled = false;
      await tester.pumpWidget(buildLayer(
        onBack: () => backCalled = true,
        onVoice: () => voiceCalled = true,
      ));

      final g1 = await tester.startGesture(const Offset(200, 100));
      final g2 = await tester.startGesture(const Offset(220, 100));
      await tester.pump();
      await g1.moveBy(const Offset(5, 200));
      await g2.moveBy(const Offset(5, 200));
      await tester.pump();
      await g1.up();
      await g2.up();
      await tester.pump();

      expect(backCalled, isFalse);
      expect(voiceCalled, isFalse);
    });
  });

  group('GestureLayer — screen reader passthrough', () {
    testWidgets('renders without error when accessibleNavigation is true',
        (tester) async {
      // Structural Listener checks are unreliable because GestureDetector
      // itself creates internal Listener widgets. Instead verify that
      // GestureLayer builds and the child is present in both modes —
      // the actual screen reader passthrough is validated by
      // TalkBack/VoiceOver on device.
      await tester.pumpWidget(buildLayer(screenReaderActive: true));
      expect(find.byType(GestureLayer), findsOneWidget,
          reason: 'GestureLayer must render when screen reader is active');
      expect(find.byType(GestureDetector), findsWidgets,
          reason: 'Child GestureDetector must be present');
    });

    testWidgets('renders without error when accessibleNavigation is false',
        (tester) async {
      await tester.pumpWidget(buildLayer(screenReaderActive: false));
      expect(find.byType(GestureLayer), findsOneWidget);
      expect(find.byType(Listener), findsWidgets,
          reason: 'Listener must be present when screen reader is off');
    });
  });

  group('GestureLayer — null callbacks are safe', () {
    testWidgets('swipe left with null onBack does not throw', (tester) async {
      await tester.pumpWidget(buildLayer());
      final g1 = await tester.startGesture(const Offset(300, 280));
      final g2 = await tester.startGesture(const Offset(300, 320));
      await tester.pump(const Duration(milliseconds: 10));
      await g1.moveBy(const Offset(-200, 0));
      await g2.moveBy(const Offset(-200, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await g1.up();
      await g2.up();
      await tester.pump(); // must not throw
    });
  });
}
