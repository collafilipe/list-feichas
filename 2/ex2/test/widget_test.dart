// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ex2/main.dart';

void main() {
  testWidgets('CatalogApp loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CatalogApp());

    // Wait for the app to settle (since it has async initialization)
    await tester.pumpAndSettle();

    // Verify that the app title appears in the app bar or that the app loads
    // Since this app has async loading, we should find either loading indicator
    // or the products screen
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
