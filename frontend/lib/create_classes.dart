import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:bottom_picker/resources/time.dart';
import 'package:frontend/api_service.dart';

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

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _coachAssignedController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _typeOfClassController = TextEditingController();
  final TextEditingController _registeredUsersController = TextEditingController();

  List<Map<String, dynamic>> _goals = [];
  dynamic _selectedGoalId;
  int? _selectedDifficulty;
  int? _selectedClassType;
  bool? _selectedRecurring;

  final Map<int, String> _classTypes = const {
    1: 'TaeKwonDo',
    2: 'Hapkido',
    3: 'Judo',
    4: 'Karate',
    5: 'Other'
  };
  
  late List<Map<String, dynamic>> _coaches;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _loadCoaches();
  }

  // fetches list of coaches from API
  Future<void> _loadCoaches() async {
    try {
      final list = await ApiService.getCoaches();
      // You can use this list to populate a dropdown or autocomplete for coach selection
      setState(() {
        _coaches = List<Map<String, dynamic>>.from(list);
      });
    } catch (_) {}
  }

  Future<void> _loadGoals() async {
    try {
      final list = await ApiService.getGoals();
      setState(() => _goals = List<Map<String, dynamic>>.from(list));
    } catch (_) {}
  }

  Future<void> _createClass() async {
    final className = _classNameController.text.trim();
    final coachAssigned = _coachAssignedController.text.trim();
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    final difficulty = _selectedDifficulty ?? 0;
    final recurring = _selectedRecurring ?? false;
    final typeOfClass = _selectedClassType ?? 0;
    final registeredUsersText = _registeredUsersController.text.trim();

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
      registeredUsers = {};
    }

    if (className.isEmpty || coachAssigned.isEmpty || date.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields')),
      );
      return;
    }

    try {
      final classData = {
        'class_name': className,
        'coach_assigned': coachAssigned,
        'date': date,
        'time': time,
        'difficulty': difficulty,
        'reccuring': recurring,
        'type_of_class': typeOfClass,
        'registered_users': registeredUsers,
        if (_selectedGoalId != null) 'goal_id': _selectedGoalId,
      };

      final insertResp = await ApiService.createClass(classData);
      final newClassId = insertResp['id'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully')),
      );

      _classNameController.clear();
      _coachAssignedController.clear();
      _dateController.clear();
      _timeController.clear();
      _difficultyController.clear();
      _typeOfClassController.clear();
      _registeredUsersController.clear();
      setState(() {
        _selectedGoalId = null;
        _selectedDifficulty = null;
        _selectedClassType = null;
        _selectedRecurring = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating class: $e')),
      );
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
                'Create New Class',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Class Name
              TextField(
                controller: _classNameController,
                decoration: _bubbleDecoration('Class Name'),
              ),
              const SizedBox(height: 20),

                // Coach Assigned (owner -> choose from dropdown of coaches; coach -> auto-fill themselves)
                FutureBuilder<Map<String, dynamic>?>(
                future: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return null;

                  // fetch current user's profile
                  final profile = await ApiService.getProfile(user.id);
                  
                  // if owner, also fetch all coaches
                  List<Map<String, dynamic>> coaches = [];
                  final role = profile['Role']?.toString().toLowerCase();
                  if (role == 'owner') {
                    coaches = await ApiService.getCoaches();
                  }

                  return {
                  'profile': profile,
                  'coaches': coaches,
                  };
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))));
                  }

                  final data = snapshot.data;
                  final profile = data?['profile'] as Map<String, dynamic>?;
                  final coaches = List<Map<String, dynamic>>.from(data?['coaches'] as List? ?? []);
                  final role = profile?['Role']?.toString().toLowerCase();
                  final username = profile?['username']?.toString() ?? '';

                  if (role == 'owner') {
                  return Column(
                    children: [
                    DropdownButtonFormField<String>(
                      value: _coachAssignedController.text.isEmpty ? null : _coachAssignedController.text,
                      decoration: _bubbleDecoration('Coach Assigned'),
                      items: coaches
                        .map((c) => DropdownMenuItem<String>(
                          value: c['username']?.toString() ?? '',
                          child: Text(c['username']?.toString() ?? ''),
                          ))
                        .toList(),
                      onChanged: (v) {
                      setState(() {
                        _coachAssignedController.text = v ?? '';
                      });
                      },
                    ),
                    const SizedBox(height: 20),
                    ],
                  );
                  } else {
                  // coach or fallback: show read-only field with their username
                  if (_coachAssignedController.text.isEmpty && username.isNotEmpty) {
                    // set controller once to avoid interfering with user edits (readOnly)
                    _coachAssignedController.text = username;
                  }
                  return Column(
                    children: [
                    TextField(
                      controller: _coachAssignedController,
                      readOnly: true,
                      decoration: _bubbleDecoration('Coach Assigned'),
                    ),
                    const SizedBox(height: 20),
                    ],
                  );
                  }
                },
                ),

              // Date Picker
              GestureDetector(
                onTap: () {
                  BottomPicker.date(
                    pickerTitle: const Text(
                      'Select Class Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    minDateTime: DateTime.now(),
                    maxDateTime: DateTime.now().add(const Duration(days: 365 * 2)),
                    onSubmit: (date) {
                      _dateController.text =
                          '${date.month}-${date.day}-${date.year}';
                      setState(() {});
                    },
                    backgroundColor: AppColors.background,
                  ).show(context);
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _dateController,
                    decoration: _bubbleDecoration('Date (MM-DD-YYYY)'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time Picker
              GestureDetector(
                onTap: () {
                  BottomPicker.time(
                    pickerTitle: const Text(
                      'Select Time',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    initialTime: Time(hours: 12),
                    onSubmit: (time) {
                      _timeController.text =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                      setState(() {});
                    },
                    backgroundColor: AppColors.background,
                  ).show(context);
                },
                child: AbsorbPointer(
                  child: TextField(
                    controller: _timeController,
                    decoration: _bubbleDecoration('Time (HH:MM)'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Difficulty Dropdown
              DropdownButtonFormField<int>(
                value: _selectedDifficulty,
                decoration: _bubbleDecoration('Difficulty (1–5)'),
                items: List.generate(
                  5,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('Level ${i + 1}')),
                ),
                onChanged: (v) => setState(() => _selectedDifficulty = v),
              ),
              const SizedBox(height: 20),

              // Recurring Dropdown
              DropdownButtonFormField<bool>(
                value: _selectedRecurring,
                decoration: _bubbleDecoration('Recurring'),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Yes')),
                  DropdownMenuItem(value: false, child: Text('No')),
                ],
                onChanged: (v) => setState(() => _selectedRecurring = v),
              ),
              const SizedBox(height: 20),

              // Type of Class Dropdown
              DropdownButtonFormField<int>(
                value: _selectedClassType,
                decoration: _bubbleDecoration('Type of Class'),
                items: _classTypes.entries
                    .map(
                      (e) => DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedClassType = v),
              ),
              const SizedBox(height: 20),

              // Goal Dropdown
              DropdownButtonFormField<dynamic>(
                value: _selectedGoalId,
                decoration: _bubbleDecoration('Goal'),
                items: _goals.map((g) {
                  return DropdownMenuItem<dynamic>(
                    value: g['id'],
                    child: Text('${g['title']} (${g['required_sessions'] ?? 0} sessions)'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedGoalId = v),
              ),
              const SizedBox(height: 30),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Class',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
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
