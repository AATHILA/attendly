import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/main.dart';

void main() {
  testWidgets('Attendly app smoke test - displays login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AttendlyApp());
    await tester.pumpAndSettle();

    // Verify that Login Screen elements are present
    expect(find.text('Attendly'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });
}
