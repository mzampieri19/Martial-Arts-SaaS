// A screen that alows coaches and owners create classes and sends it to the database
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

class CreateClassesPage extends StatefulWidget {
  const CreateClassesPage({super.key});

  @override
  State<CreateClassesPage> createState() => _CreateClassesPageState();
}

class _CreateClassesPageState extends State<CreateClassesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _coachAssignedController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _recurringController = TextEditingController();
  final TextEditingController _typeOfClassController = TextEditingController();
  final TextEditingController _registeredUsersController = TextEditingController();
  // Goals dropdown state
  List<Map<String, dynamic>> _goals = [];
  dynamic _selectedGoalId;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final resp = await _supabase.from('goals').select('id, key, title, required_sessions').order('title', ascending: true);
      final list = List<Map<String, dynamic>>.from(resp as List? ?? []);
      setState(() { _goals = list; });
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _coachAssignedController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _difficultyController.dispose();
    _recurringController.dispose();
    _typeOfClassController.dispose();
    _registeredUsersController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    final className = _classNameController.text.trim();
    final coachAssigned = _coachAssignedController.text.trim();
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    final difficulty = int.tryParse(_difficultyController.text.trim()) ?? 0;
    final recurring = _recurringController.text.trim().toLowerCase() == 'false';
    final typeOfClass = int.tryParse(_typeOfClassController.text.trim()) ?? 0;
    final registeredUsersText = _registeredUsersController.text.trim();
    
    // Parse registered users as JSON
    Map<String, dynamic>? registeredUsers;
    if (registeredUsersText.isNotEmpty) {
      try {
        registeredUsers = jsonDecode(registeredUsersText) as Map<String, dynamic>;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON format for registered users')),
        );
        return;
      }
    } else {
      // Default empty JSON object
      registeredUsers = {};
    }

    if (className.isEmpty || coachAssigned.isEmpty || date.isEmpty || time.isEmpty || difficulty < 0 || typeOfClass < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    try {
      final insertResp = await _supabase.from('classes').insert({
        'class_name': className,
        'coach_assigned': coachAssigned,
        'date': date,
        'time': time,
        'difficulty': difficulty,
        'reccuring': recurring,
        'type_of_class': typeOfClass,
        'registered_users': registeredUsers, // Now a JSON object
      }).select('id');

      final inserted = List<Map<String, dynamic>>.from(insertResp as List? ?? []);
      final newClassId = inserted.isNotEmpty ? inserted.first['id'] : null;

      // Create class_goal_links entry if a goal was selected
      if (_selectedGoalId != null && newClassId != null) {
        try {
          // Ensure goal id is the proper numeric type when possible
          final parsedGoalId = int.tryParse(_selectedGoalId.toString()) ?? _selectedGoalId;
          final linkResp = await _supabase.from('class_goal_links').insert({
            'class_id': newClassId,
            'goal_id': parsedGoalId,
          }).select();

          final inserted = List<Map<String, dynamic>>.from(linkResp as List? ?? []);
          if (inserted.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Class created but linking goal failed (no rows returned)')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Class created but failed to link goal: $e')),
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully')),
      );

      _classNameController.clear();
      _coachAssignedController.clear();
      _dateController.clear();
      _timeController.clear();
      _difficultyController.clear();
      _recurringController.clear();
      _typeOfClassController.clear();
      _registeredUsersController.clear();
      setState(() { _selectedGoalId = null; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating class: $e')),
      );
    }
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
            children: [
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Create New Class',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Class Name
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _classNameController,
                  decoration: const InputDecoration(labelText: 'Class Name'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Coach Assigned
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _coachAssignedController,
                  decoration: const InputDecoration(labelText: 'Coach Assigned'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Date
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Date (MM-DD-YYYY)'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Time
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Difficulty
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _difficultyController,
                  decoration: const InputDecoration(labelText: 'Difficulty (0-5)'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Recurring
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _recurringController,
                  decoration: const InputDecoration(labelText: 'Recurring (true/false)'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Type of Class helper text
              Container(
                width: 320,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Class Types: 1 = TaeKwonDo, 2 = Hapkido, 3 = Judo, 4 = Karate, 5 = Other',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Type of Class
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _typeOfClassController,
                  decoration: const InputDecoration(labelText: 'Type of Class (1-5)'),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: 32),

              // Goal selection
              SizedBox(
                width: 320,
                child: DropdownButtonFormField<dynamic>(
                  value: _selectedGoalId,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items: _goals.map((g) {
                    return DropdownMenuItem<dynamic>(
                      value: g['id'],
                      child: Text('${g['title']} (${g['required_sessions'] ?? 0} sessions)'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() { _selectedGoalId = v; }),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: 320,
                height: 48,
                child: ElevatedButton(
                  onPressed: _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create Class',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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