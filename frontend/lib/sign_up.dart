import 'package:flutter/material.dart';
import 'package:frontend/home.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  File? _selectedImage;

  void _navigateToHomePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
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
                  const SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Username'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Email
                  const SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Password
                  const SizedBox(
                    width: 320,
                    child: TextField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: 320,
                    child: ElevatedButton(
                      onPressed: _navigateToHomePage,
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
