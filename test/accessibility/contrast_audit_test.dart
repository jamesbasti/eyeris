import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/core/app_theme.dart';

double _linearise(int value) {
  final c = value / 255.0;
  if (c <= 0.04045) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double relativeLuminance(Color color) =>
    0.2126 * _linearise(color.red) +
    0.7152 * _linearise(color.green) +
    0.0722 * _linearise(color.blue);

double contrastRatio(Color fg, Color bg) {
  final lighter = math.max(relativeLuminance(fg), relativeLuminance(bg));
  final darker  = math.min(relativeLuminance(fg), relativeLuminance(bg));
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const aa  = 4.5;
  const aaa = 7.0;

  group('EyerisColors contrast ratios', () {
    test('textPrimary on background >= 7:1', () {
      final r = contrastRatio(EyerisColors.textPrimary, EyerisColors.background);
      expect(r, greaterThanOrEqualTo(aaa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('primary yellow on background >= 7:1', () {
      final r = contrastRatio(EyerisColors.primary, EyerisColors.background);
      expect(r, greaterThanOrEqualTo(aaa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('textOnPrimary (black) on primary yellow >= 7:1', () {
      final r = contrastRatio(EyerisColors.textOnPrimary, EyerisColors.primary);
      expect(r, greaterThanOrEqualTo(aaa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('textPrimary on surface >= 7:1', () {
      final r = contrastRatio(EyerisColors.textPrimary, EyerisColors.surface);
      expect(r, greaterThanOrEqualTo(aaa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('primary yellow on surface >= 7:1', () {
      final r = contrastRatio(EyerisColors.primary, EyerisColors.surface);
      expect(r, greaterThanOrEqualTo(aaa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('danger on background meets AA (>= 4.5:1)', () {
      final r = contrastRatio(EyerisColors.danger, EyerisColors.background);
      expect(r, greaterThanOrEqualTo(aa), reason: 'Got ${r.toStringAsFixed(2)}:1');
    });

    test('primary yellow readable in greyscale (protanopia sim)', () {
      const r = 0xFF, g = 0xD1, b = 0x00;
      final grey = (r * 0.299 + g * 0.587 + b * 0.114).round();
      final yellowGrey = Color.fromRGBO(grey, grey, grey, 1.0);
      const bgGrey = Color.fromRGBO(10, 10, 10, 1.0);
      final ratio = contrastRatio(yellowGrey, bgGrey);
      expect(ratio, greaterThanOrEqualTo(aa),
          reason: 'Greyscale sim: ${ratio.toStringAsFixed(2)}:1');
    });

    test('danger and primary have distinct luminance', () {
      final diff = (relativeLuminance(EyerisColors.danger) -
              relativeLuminance(EyerisColors.primary))
          .abs();
      expect(diff, greaterThan(0.05));
    });
  });
}
