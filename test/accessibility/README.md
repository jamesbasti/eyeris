# Eyeris Accessibility Test Suite

Located in `test/accessibility/`. Run with:

```bash
flutter test test/accessibility/
```

Run a single file:

```bash
flutter test test/accessibility/contrast_audit_test.dart
```

---

## Files

| File | What it tests |
|------|--------------|
| `contrast_audit_test.dart` | WCAG contrast ratios — all colour pairs ≥7:1 AAA |
| `touch_targets_test.dart` | Touch target sizes — all targets ≥44px WCAG floor |
| `semantics_labels_test.dart` | ARIA/Semantics — every button has a descriptive label |
| `focus_order_test.dart` | Focus traversal — back button first, mic last, logical order |
| `gesture_layer_test.dart` | GestureLayer — swipe callbacks, threshold guards, screen reader passthrough |

---

## Interpreting failures

### Contrast audit failures
A failure prints the actual ratio, e.g.:
```
Expected: ≥7.0
  Actual: 4.2
Reason: Expected ≥7:1, got 4.20:1
```
Fix by adjusting the failing colour in `lib/core/app_theme.dart`.

### Touch target failures
```
Expected: ≥44.0
  Actual: 36.0
Reason: Back button is 36px — must be ≥44px
```
Fix by increasing the widget's `width`/`height` in the relevant widget file.

### Semantics label failures
```
Button at Rect.fromLTRB(...) has empty label
```
Find the widget at that screen position and add a non-empty `semanticsLabel` prop or `Semantics(label: '...')` wrapper.

```
Button "›" fails descriptive label check
```
The arrow glyph was accidentally included in semantics. Wrap it in `ExcludeSemantics`.

### Focus order failures
```
Back button must be index 0, was index 3
```
The widget tree is rendering the back button after other focusable elements. Check the order of children in the screen's `Column`.

### GestureLayer failures
```
2-finger left swipe must call onBack
```
The pointer tracking in `GestureLayer` is not counting fingers correctly. Check `_onPointerDown` / `_onPointerUp` logic.

```
Single-finger drag must not trigger 2-finger callback
```
The `_activePointers` guard is not working. Verify `_activePointers >= 2` check in `_evaluateSwipe`.

---

## Adding tests for new screens

1. Import the new screen and `buildEyerisTheme()`.
2. Pump the screen with `tester.pumpWidget(MaterialApp(theme: buildEyerisTheme(), home: const YourScreen()))`.
3. Use `orderedButtonNodes(tester)` (from `focus_order_test.dart`) or `findButtonNodes(tester)` (from `semantics_labels_test.dart`) to collect nodes.
4. Assert: back button is index 0, all labels are descriptive, count matches expected number of actions.

Pattern:
```dart
testWidgets('YourScreen — back button is first', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildEyerisTheme(),
      home: const YourScreen(onBack: () {}),
    ),
  );
  await tester.pump();

  final buttons = orderedButtonNodes(tester);
  final backIndex = buttons.indexWhere(
    (b) => b.node.label.toLowerCase().contains('back'),
  );
  expect(backIndex, equals(0));
});
```
