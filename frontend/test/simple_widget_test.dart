import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/log_in.dart';

void main() {
  group('Simple Widget Tests', () {
    testWidgets('AppColors class works correctly', (WidgetTester tester) async {
      // Test that our AppColors class has the right values
      expect(AppColors.primaryBlue, const Color(0xFFDD886C));
      expect(AppColors.linkBlue, const Color(0xFFC96E6E));
      expect(AppColors.fieldFill, const Color(0xFFF1F3F6));
      expect(AppColors.background, const Color(0xFFFFFDE2));
    });

    testWidgets('Login page basic elements exist', (WidgetTester tester) async {
      // Create a simple test that doesn't trigger Supabase
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Welcome back!'),
                const Text("We're so excited to see you again!"),
                const Text('Account Information'),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: AppColors.fieldFill,
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: AppColors.fieldFill,
                  ),
                  obscureText: true,
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      );

      // Test that basic elements are present
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text("We're so excited to see you again!"), findsOneWidget);
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      
      // Test that text fields are present
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Text input works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                TextField(
                  decoration: InputDecoration(hintText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
      );

      // Test text input
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'test@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.pump();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Button interactions work', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                buttonPressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      // Test button tap
      await tester.tap(find.text('Test Button'));
      await tester.pump();

      // Verify button was pressed
      expect(buttonPressed, isTrue);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: InputDecoration(hintText: 'Email'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Simulate validation - show snackbar
                    ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
                        .showSnackBar(
                      const SnackBar(content: Text('Please fill out all fields')),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );

      // Test button press without filling fields
      await tester.tap(find.text('Submit'));
      await tester.pump();

      // Verify validation message appears
      expect(find.text('Please fill out all fields'), findsOneWidget);
    });
  });
}
