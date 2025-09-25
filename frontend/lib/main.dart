import 'package:flutter/material.dart';
import 'package:frontend/components/app_button.dart'; // keep if you use it elsewhere

import 'log_in.dart';
import 'sign_up.dart';
import 'home.dart';

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

class AppColors {
  static const primary = Color(0xFFDD886C); // buttons
  static const link = Color(0xFFC96E6E);
  static const background = Color(0xFFFFFDE2);
  static const surfaceLight = Color(0xFFF6F1EA);
  static const textDark = Color(0xFF202124);
  static const textSubtle = Color(0x99000000);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Martial Arts Saas App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.link),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const MyHomePage(title: "Martial Arts App"),
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

  Widget _bubble(IconData icon) {
    return Container(
      width: 110,
      height: 110,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        title: const SizedBox.shrink(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // logo + name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_mma, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'GYM CALENDAR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // bubbles
              SizedBox(
                height: 210,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(top: 12, left: 10, child: _bubble(Icons.sports_kabaddi)),
                    Positioned(top: 0, right: 6, child: _bubble(Icons.fitness_center)),
                    Positioned(bottom: 4, child: _bubble(Icons.self_improvement)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // title
              Text(
                'Track your events and progress!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),

              // subtitle
              Text(
                'idk placeholder placeholder placeholder',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSubtle,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),
              // (buttons removed from here)
            ],
          ),
        ),
      ),

      // ✅ Fixed bottom buttons
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToSignUpPage,
                child: const Text(
                  'Register',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _navigateToLogInPage,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(color: Colors.black.withOpacity(0.35), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: AppColors.textDark,
                  backgroundColor: Colors.black.withOpacity(0.07),
                ),
                child: const Text(
                  'Log In',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}