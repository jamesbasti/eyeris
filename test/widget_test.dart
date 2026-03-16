import 'package:flutter_test/flutter_test.dart';
import 'package:eyeris/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const EyerisApp());
    await tester.pumpAndSettle();

    // App should render successfully
    expect(find.byType(EyerisApp), findsOneWidget);
  });
}
