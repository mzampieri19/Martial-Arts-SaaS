import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  File? _selectedImage;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // input box design - same as login page
  InputDecoration _input(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffix,
    );
  }

  void _navigateToHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Create Your Profile!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  "Let's get you started!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              
              // Profile photo placeholder - centered
              Center(
                child: GestureDetector(
                  onTap: () async {
                    // TODO: Implement profile photo upload
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setState(() {
                        _selectedImage = File(image.path);
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: const Color.fromRGBO(255, 253, 226, 1),
                    backgroundImage: _selectedImage != null 
                      ? FileImage(_selectedImage!) 
                      : null,
                    child: _selectedImage == null
                      ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]) 
                      : null,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Username
              TextField(
                controller: _usernameController,
                decoration: _input('Username'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Email
              TextField(
                controller: _emailController,
                decoration: _input('Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),

              // Password
              TextField(
                controller: _passwordController,
                decoration: _input('Password'),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final username = _usernameController.text.trim();
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    if (username.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill out all fields')),
                      );
                      return;
                    }

                    final supabase = Supabase.instance.client;

                    try {
                      // 1) Create auth user
                      final signUpRes = await supabase.auth.signUp(
                        email: email,
                        password: password,
                      );

                      final user = signUpRes.user;
                      if (user == null) {
                        // Email confirmation likely enabled
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Check your email to confirm your account.')),
                        );
                        return;
                      }

                      // 2) Set username on profiles (unique)
                      try {
                        await supabase
                            .from('profiles')
                            .upsert({'id': user.id, 'username': username});
                      } on PostgrestException catch (e) {
                        // Log exact DB error for debugging
                        // ignore: avoid_print
                        print('PostgrestException ${e.code}: ${e.message}');
                        // Unique violation code is typically 23505
                        if (e.code == '23505') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Username is taken. Choose another.')),
                          );
                          return;
                        }
                        // Show the DB error to the user for other cases
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Database error: ${e.message}')),
                        );
                        return;
                      }

                      // 3) Optional avatar upload to Storage (store path regardless of public/private)
                      if (_selectedImage != null) {
                        final String filePath = '${user.id}/profile.jpg';
                        try {
                          await supabase.storage
                              .from('avatars')
                              .upload(filePath, _selectedImage!, fileOptions: const FileOptions(upsert: true));

                          await supabase
                              .from('profiles')
                              .upsert({'id': user.id, 'avatar_url': filePath});
                        } catch (_) {
                          // Non-fatal: proceed without blocking signup
                        }
                      }

                      // 4) Navigate on success
                      _navigateToHomePage();
                    } on AuthException catch (e) {
                      // ignore: avoid_print
                      print('AuthException: ${e.message}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    } catch (e) {
                      // ignore: avoid_print
                      print('Unexpected error during sign up: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign up failed. Try again.')),
                      );
                    }
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}