// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smart_factory_app/main.dart';

void main() {
  testWidgets('Products list screen displays products', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartFactoryApp());

    // Verify that the products list screen is displayed
    expect(find.text('Smart Factory'), findsWidgets);
    
    // Verify that product cards are displayed
    expect(find.text('Maintenance of Closed Loop Systems'), findsOneWidget);
    expect(find.text('PLC Fundamentals'), findsOneWidget);
  });
}
