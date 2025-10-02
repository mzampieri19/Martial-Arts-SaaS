import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Landing page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('GYM CALENDAR'), findsOneWidget);
    expect(find.text('Track your events and progress!'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create Your Profile!'), findsOneWidget);
  });
}
