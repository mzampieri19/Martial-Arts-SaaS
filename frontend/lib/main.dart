import 'package:flutter/material.dart';
// keep if you use it elsewhere
import 'package:supabase_flutter/supabase_flutter.dart';

import 'log_in.dart';
import 'sign_up.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Replace with your Supabase project credentials from app.supabase.com → Project Settings → API
  const String supabaseUrl = 'https://nopgyqscrjjkyapwcqwf.supabase.co';
  const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5vcGd5cXNjcmpqa3lhcHdjcXdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTQwNDAsImV4cCI6MjA3NDM5MDA0MH0.uBoO5pTD7p4fumInzsfWQYt4LlcYuABFMWeA1EHvaLE';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    // authFlowType: AuthFlowType.pkce, // default; keep if you add magic links/OAuth later
  );

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
                  // Logo image (place `assets/images/logo.png`). If missing, falls back to an icon.
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      // match the page background so the logo visually blends in
                      color: Color.fromRGBO(255, 253, 226, 1),
                    ),
                    child: Image.asset(
                      '/images/new_new_logo.png',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.sports_mma, color: AppColors.primary, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'BOOK A FIGHT',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),                  
                ],
              ),
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