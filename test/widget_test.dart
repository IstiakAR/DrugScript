import 'package:flutter_test/flutter_test.dart';
import 'package:drugscript/main.dart';

void main() {
  group('DrugScript App', () {
    testWidgets('App launches and shows DrugScript splash title', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Splash screen should display app name
      expect(find.text('DrugScript'), findsOneWidget);

      // Wait for splash duration and navigation
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // You may want to check for the next screen here, e.g.
      // expect(find.byType(Wrapper), findsOneWidget);
      // or check bottom navigation bar, home screen, etc.
    });

    // Example: Add more tests for your main screens/routes
    // testWidgets('Home screen shows expected content', (WidgetTester tester) async {
    //   await tester.pumpWidget(const MyApp());
    //   await tester.pumpAndSettle(const Duration(seconds: 3));
    //   expect(find.text('Some Home Widget'), findsOneWidget);
    // });
  });
}