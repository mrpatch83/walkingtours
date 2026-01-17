import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:walking_tour_app/main.dart';

void main() {
  testWidgets('App shows list of tours and title', (WidgetTester tester) async {
    await tester.pumpWidget(WalkingTourApp());

    // One of the sample tours should appear on the feed
    expect(find.text('City Highlights'), findsOneWidget);
  });
}