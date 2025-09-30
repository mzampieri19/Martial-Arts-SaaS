import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';



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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Center(
                    child: Text(
                      'Create Your Profile!',
                        style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        ),
                    ),
                  ),
                  // Profile photo placeholder
                  GestureDetector(
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
                    child:
                    CircleAvatar(
                      radius: 80,
                      backgroundColor: const Color.fromRGBO(255,	253, 226, 1),
                      backgroundImage: _selectedImage != null 
                        ? FileImage(_selectedImage!) 
                        : null,
                      child: _selectedImage == null
                        ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey[600]) 
                        : null,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Username
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Password
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: 320,
                    child: ElevatedButton(
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
                      child: const Text('Sign Up'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
