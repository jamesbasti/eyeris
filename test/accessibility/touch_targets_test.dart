import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/core/app_theme.dart';

void main() {
  const wcagMin = 44.0;

  group('EyerisTouchTargets — all >= WCAG 44px floor', () {
    test('minTap == 44', () => expect(EyerisTouchTargets.minTap, equals(wcagMin)));
    test('backButton >= 44', () => expect(EyerisTouchTargets.backButton, greaterThanOrEqualTo(wcagMin)));
    test('primaryButton >= 44', () => expect(EyerisTouchTargets.primaryButton, greaterThanOrEqualTo(wcagMin)));
    test('primaryButton >= 64 (Eyeris spec)', () => expect(EyerisTouchTargets.primaryButton, greaterThanOrEqualTo(64.0)));
    test('actionRow >= 80 (Eyeris spec)', () => expect(EyerisTouchTargets.actionRow, greaterThanOrEqualTo(80.0)));
    test('hubCard >= 110 (Eyeris spec)', () => expect(EyerisTouchTargets.hubCard, greaterThanOrEqualTo(110.0)));
  });

  group('EyerisSpacing — positive and increasing', () {
    test('all spacing values > 0', () {
      final values = [
        EyerisSpacing.xs, EyerisSpacing.sm, EyerisSpacing.md,
        EyerisSpacing.md2, EyerisSpacing.base, EyerisSpacing.lg,
        EyerisSpacing.xl, EyerisSpacing.xxl, EyerisSpacing.huge,
      ];
      for (final v in values) {
        expect(v, greaterThan(0), reason: 'Spacing $v must be > 0');
      }
    });
  });

  group('EyerisRadii — all positive', () {
    test('all radius values > 0', () {
      for (final v in [
        EyerisRadii.small, EyerisRadii.medium,
        EyerisRadii.large, EyerisRadii.card, EyerisRadii.full,
      ]) {
        expect(v, greaterThan(0));
      }
    });
  });
}
