import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/ui/home_screen.dart';
import 'package:eyeris/ui/read_screen.dart';
import 'package:eyeris/ui/navigate_screen.dart';
import 'package:eyeris/ui/identify_screen.dart';
import 'package:eyeris/ui/communicate_screen.dart';

List<({SemanticsNode node, Rect rect})> orderedButtonNodes(WidgetTester tester) {
  final result = <({SemanticsNode node, Rect rect})>[];

  void visit(SemanticsNode node) {
    // ignore: deprecated_member_use
    if (node.hasFlag(SemanticsFlag.isButton) && !node.isMergedIntoParent) {
      final transform = node.transform;
      final localRect = node.rect;
      final topLeft = transform != null
          ? MatrixUtils.transformPoint(transform, localRect.topLeft)
          : localRect.topLeft;
      final bottomRight = transform != null
          ? MatrixUtils.transformPoint(transform, localRect.bottomRight)
          : localRect.bottomRight;
      result.add((node: node, rect: Rect.fromPoints(topLeft, bottomRight)));
    }
    node.visitChildren((child) { visit(child); return true; });
  }

  visit(tester.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode!);

  result.sort((a, b) {
    const threshold = 20.0;
    final dy = a.rect.top - b.rect.top;
    if (dy.abs() > threshold) return dy.sign.toInt();
    return (a.rect.left - b.rect.left).sign.toInt();
  });

  return result;
}

Widget eyerisApp(Widget home) => MaterialApp(
      theme: buildEyerisTheme(),
      home: home,
    );

void main() {
  group('HomeScreen focus order', () {
    testWidgets('no button has an empty label', (tester) async {
      await tester.pumpWidget(eyerisApp(const HomeScreen()));
      await tester.pump();
      final btns = orderedButtonNodes(tester);
      expect(btns, isNotEmpty);
      for (final b in btns) {
        expect(b.node.label.trim().isNotEmpty, isTrue,
            reason: 'Button at ${b.rect} has empty label');
      }
    });

    testWidgets('has >= 5 focusable buttons', (tester) async {
      await tester.pumpWidget(eyerisApp(const HomeScreen()));
      await tester.pump();
      expect(orderedButtonNodes(tester).length, greaterThanOrEqualTo(5));
    });
  });

  group('ReadScreen focus order', () {
    testWidgets('back button is first focusable element', (tester) async {
      await tester.pumpWidget(eyerisApp(ReadScreen(onBack: () {})));
      await tester.pump();
      final btns = orderedButtonNodes(tester);
      expect(btns, isNotEmpty);
      final backIdx = btns.indexWhere(
          (b) => b.node.label.toLowerCase().contains('back'));
      expect(backIdx, equals(0),
          reason: 'Back button must be index 0, was $backIdx');
    });

    testWidgets('no button has an empty label', (tester) async {
      await tester.pumpWidget(eyerisApp(ReadScreen(onBack: () {})));
      await tester.pump();
      for (final b in orderedButtonNodes(tester)) {
        expect(b.node.label.trim().isNotEmpty, isTrue,
            reason: 'Empty label at ${b.rect}');
      }
    });
  });

  group('NavigateScreen focus order', () {
    testWidgets('back button is first focusable element', (tester) async {
      await tester.pumpWidget(eyerisApp(NavigateScreen(onBack: () {})));
      await tester.pump();
      final btns = orderedButtonNodes(tester);
      final backIdx = btns.indexWhere(
          (b) => b.node.label.toLowerCase().contains('back'));
      expect(backIdx, equals(0),
          reason: 'Back button must be index 0, was $backIdx');
    });

    testWidgets('no empty labels', (tester) async {
      await tester.pumpWidget(eyerisApp(NavigateScreen(onBack: () {})));
      await tester.pump();
      for (final b in orderedButtonNodes(tester)) {
        expect(b.node.label.trim().isNotEmpty, isTrue);
      }
    });
  });

  group('IdentifyScreen focus order', () {
    testWidgets('back button is first focusable element', (tester) async {
      await tester.pumpWidget(eyerisApp(IdentifyScreen(onBack: () {})));
      await tester.pump();
      final btns = orderedButtonNodes(tester);
      final backIdx = btns.indexWhere(
          (b) => b.node.label.toLowerCase().contains('back'));
      expect(backIdx, equals(0));
    });
  });

  group('CommunicateScreen focus order', () {
    testWidgets('back button is first, SOS is not first', (tester) async {
      await tester.pumpWidget(
          eyerisApp(CommunicateScreen(onBack: () {})));
      await tester.pump();
      final btns = orderedButtonNodes(tester);
      expect(btns, isNotEmpty);

      final backIdx = btns.indexWhere(
          (b) => b.node.label.toLowerCase().contains('back'));
      expect(backIdx, equals(0), reason: 'Back must be first');

      final sosIdx = btns.indexWhere((b) =>
          b.node.label.toLowerCase().contains('sos') ||
          b.node.label.toLowerCase().contains('emergency'));
      expect(sosIdx, greaterThan(0),
          reason: 'SOS must not be the first focusable element');
    });
  });
}
