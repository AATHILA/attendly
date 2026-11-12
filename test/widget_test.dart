import 'package:flutter_test/flutter_test.dart';
import 'package:attendly/main.dart';

void main() {
  testWidgets('AttendlyApp loads and displays Login screen', (WidgetTester tester) async {
    // Build our Attendly app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the Attendly title and Sign In button are displayed.
    expect(find.text('Attendly'), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
