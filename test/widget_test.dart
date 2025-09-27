import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';



void main() {
  testWidgets('simple icon smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Icon(Icons.shopping_bag))),
      ),
    );

    expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
  });
}
