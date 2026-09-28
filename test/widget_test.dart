// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:email_addresses_redesign/main.dart';

void main() {
  testWidgets('shows the default multiple-email journey', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EmailRedesignApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Email addresses'), findsOneWidget);
    expect(find.text('Contact email'), findsOneWidget);
    expect(find.text('3 emails'), findsOneWidget);
    expect(find.text('1 needs verification'), findsOneWidget);
    expect(find.text('Add another email'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
  });
}
