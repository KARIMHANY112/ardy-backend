import 'package:flutter_test/flutter_test.dart';

import 'package:ardy/main.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ارضي'), findsOneWidget);
    expect(find.text('A R D I'), findsOneWidget);

    // Flush the splash screen's navigation timer so it doesn't leak past the test.
    await tester.pump(const Duration(seconds: 3));
  });
}
