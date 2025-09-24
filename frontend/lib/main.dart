import 'package:flutter/material.dart';
import 'package:frontend/components/app_button.dart';

import 'log_in.dart';
import 'sign_up.dart';

// Hi Guys this is Michael Im writing a few comments on the pages to keep track what page is which
// This is main.dart. Here we will have the landing page for the app. 
// From here the user will click log in or sign up which will take them to log_in.dart and sign_up.dart
// After they enter their details they will be taken to home.dart which is where the main page of the app is, with the nav bar. 
// From there they can go to profile.dart to see and edit their profile.

// For now I have linked all the pages together (very simply) so you can see how it works.

// Based on the sprint 1 planning doc:
// Grace works on main.dart and log_in.dart
// Jayden works on sign_up.dart 
// Michael works on home.dart
// Nancy works on profile.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _navigateToLogInPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogInPage()),
    );
  }

  void _navigateToSignUpPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Log In',
              onPressed: _navigateToLogInPage,
              variant: AppButtonVariant.primary,
              size: AppButtonSize.medium,
              fullWidth: false,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Sign Up',
              onPressed: _navigateToSignUpPage,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              fullWidth: false,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}