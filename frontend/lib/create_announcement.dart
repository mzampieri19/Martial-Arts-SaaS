import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_classes.dart';

class CreateAnnouncementPage extends StatefulWidget {
  const CreateAnnouncementPage({super.key});

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide title and body')));
      return;
    }

    setState(() => _submitting = true);
    final supabase = Supabase.instance.client;

    try {
      final currentUser = supabase.auth.currentUser;
      final createdBy = currentUser?.id;

  
      await supabase.from('announcements').insert({
        'title': title,
        'body': body,
        'created_by': createdBy,
      }).select();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement created')));

      _titleCtrl.clear();
      _bodyCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating announcement: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  InputDecoration _bubbleDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Create New Announcement',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextField(
                controller: _titleCtrl,
                decoration: _bubbleDecoration('Title'),
              ),
              const SizedBox(height: 20),

              // Body
              TextField(
                controller: _bodyCtrl,
                decoration: _bubbleDecoration('Body'),
                minLines: 4,
                maxLines: 8,
              ),
              const SizedBox(height: 20),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text(
                          'Create Announcement',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
