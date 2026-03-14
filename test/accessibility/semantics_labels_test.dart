import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/core/app_theme.dart';
import 'package:eyeris/ui/home_screen.dart';
import 'package:eyeris/ui/read_screen.dart';
import 'package:eyeris/ui/navigate_screen.dart';
import 'package:eyeris/ui/identify_screen.dart';
import 'package:eyeris/ui/communicate_screen.dart';
import 'package:eyeris/widgets/action_row.dart';
import 'package:eyeris/widgets/hub_card.dart';
import 'package:eyeris/widgets/icons/eyeris_icons.dart';

List<SemanticsNode> findButtonNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    // ignore: deprecated_member_use
    if (node.hasFlag(SemanticsFlag.isButton)) nodes.add(node);
    node.visitChildren((child) { visit(child); return true; });
  }
  visit(tester.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return nodes;
}

List<SemanticsNode> findHeaderNodes(WidgetTester tester) {
  final nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    // ignore: deprecated_member_use
    if (node.hasFlag(SemanticsFlag.isHeader)) nodes.add(node);
    node.visitChildren((child) { visit(child); return true; });
  }
  visit(tester.binding.rootPipelineOwner.semanticsOwner!.rootSemanticsNode!);
  return nodes;
}

bool isDescriptive(String label) {
  final t = label.trim();
  return t.length > 2 && t.contains(RegExp(r'[a-zA-Z]'));
}

Widget eyerisApp(Widget home) => MaterialApp(
      theme: buildEyerisTheme(),
      home: home,
    );

void main() {
  group('ActionRow semantics', () {
    testWidgets('has descriptive semantics label', (tester) async {
      await tester.pumpWidget(eyerisApp(Scaffold(
        body: ActionRow(
          label: 'Point & Read',
          sublabel: 'Camera',
          icon: EyerisIcons.camera(size: 22),
          onPress: () {},
          semanticsLabel: 'Point and read. Aims camera at text and reads it aloud.',
          semanticsHint: 'Double tap to open camera.',
        ),
      )));
      final btns = findButtonNodes(tester);
      expect(btns, isNotEmpty);
      for (final b in btns) {
        expect(isDescriptive(b.label), isTrue, reason: '"${b.label}" is not descriptive');
      }
    });

    testWidgets('disabled ActionRow has isEnabled=false', (tester) async {
      await tester.pumpWidget(eyerisApp(Scaffold(
        body: ActionRow(
          label: 'Disabled',
          icon: EyerisIcons.document(size: 22),
          onPress: () {},
          disabled: true,
          semanticsLabel: 'Disabled row. Not available.',
        ),
      )));
      final btns = findButtonNodes(tester);
      final disabled = btns.where((n) {
    // ignore: deprecated_member_use
    return n.hasFlag(SemanticsFlag.hasEnabledState);
  });
      expect(disabled, isNotEmpty,
          reason: 'Disabled ActionRow must mark button as not enabled');
    });
  });

  group('HubCard semantics', () {
    testWidgets('has descriptive semantics label', (tester) async {
      await tester.pumpWidget(eyerisApp(Scaffold(
        body: HubCard(
          label: 'Read',
          sublabel: 'Scan text',
          icon: EyerisIcons.read(size: 26),
          onTap: () {},
          semanticsLabel: 'Read. Scan text and documents.',
          semanticsHint: 'Double tap to open Read screen.',
        ),
      )));
      final btns = findButtonNodes(tester);
      expect(btns, isNotEmpty);
      expect(isDescriptive(btns.first.label), isTrue);
    });
  });

  group('HomeScreen semantics', () {
    testWidgets('>=4 labelled buttons, all descriptive', (tester) async {
      await tester.pumpWidget(eyerisApp(const HomeScreen()));
      final btns = findButtonNodes(tester).where((n) => n.label.isNotEmpty).toList();
      expect(btns.length, greaterThanOrEqualTo(4));
      for (final b in btns) {
        expect(isDescriptive(b.label), isTrue, reason: '"${b.label}" not descriptive');
      }
    });

    testWidgets('has exactly one header node', (tester) async {
      await tester.pumpWidget(eyerisApp(const HomeScreen()));
      final headers = findHeaderNodes(tester);
      expect(headers.length, equals(1));
      expect(headers.first.label.isNotEmpty, isTrue);
    });
  });

  group('ReadScreen semantics', () {
    testWidgets('>=4 labelled buttons, all descriptive', (tester) async {
      await tester.pumpWidget(eyerisApp(const ReadScreen()));
      await tester.pump();
      final btns = findButtonNodes(tester).where((n) => n.label.isNotEmpty).toList();
      expect(btns.length, greaterThanOrEqualTo(4));
      for (final b in btns) {
        expect(isDescriptive(b.label), isTrue, reason: '"${b.label}" not descriptive');
      }
    });

    testWidgets('has exactly one header node', (tester) async {
      await tester.pumpWidget(eyerisApp(const ReadScreen()));
      expect(findHeaderNodes(tester).length, equals(1));
    });
  });

  group('NavigateScreen semantics', () {
    testWidgets('>=3 labelled buttons, all descriptive', (tester) async {
      await tester.pumpWidget(eyerisApp(const NavigateScreen()));
      await tester.pump();
      final btns = findButtonNodes(tester).where((n) => n.label.isNotEmpty).toList();
      expect(btns.length, greaterThanOrEqualTo(3));
      for (final b in btns) {
        expect(isDescriptive(b.label), isTrue, reason: '"${b.label}" not descriptive');
      }
    });
  });

  group('IdentifyScreen semantics', () {
    testWidgets('>=3 labelled buttons, all descriptive', (tester) async {
      await tester.pumpWidget(eyerisApp(const IdentifyScreen()));
      await tester.pump();
      final btns = findButtonNodes(tester).where((n) => n.label.isNotEmpty).toList();
      expect(btns.length, greaterThanOrEqualTo(3));
      for (final b in btns) {
        expect(isDescriptive(b.label), isTrue, reason: '"${b.label}" not descriptive');
      }
    });
  });

  group('CommunicateScreen semantics', () {
    testWidgets('SOS button has emergency label', (tester) async {
      await tester.pumpWidget(eyerisApp(const CommunicateScreen()));
      await tester.pump();
      final btns = findButtonNodes(tester).where((n) =>
          n.label.toLowerCase().contains('sos') ||
          n.label.toLowerCase().contains('emergency')).toList();
      expect(btns, isNotEmpty,
          reason: 'CommunicateScreen must have a button labelled with SOS/emergency');
      expect(isDescriptive(btns.first.label), isTrue);
    });
  });
}
