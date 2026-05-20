import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graft_tracker_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the graft zähler screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GraftZaehlerApp());
    await tester.pumpAndSettle();

    expect(find.text('Graft Zähler'), findsOneWidget);
    expect(find.text('CSV Export'), findsOneWidget);
    expect(find.text('PDF Export'), findsOneWidget);
    expect(find.byIcon(Icons.print), findsOneWidget);
  });
}
