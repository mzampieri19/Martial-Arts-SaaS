import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:bottom_picker/resources/time.dart';
import 'package:intl/intl.dart';

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
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _difficultyController = TextEditingController();
  final TextEditingController _typeOfClassController = TextEditingController();
  final TextEditingController _registeredUsersController = TextEditingController();

  List<Map<String, dynamic>> _goals = [];
  dynamic _selectedGoalId;
  int? _selectedDifficulty;
  int? _selectedClassType;
  bool? _selectedRecurring;
  final Set<int> _selectedWeekdays = {};
  final List<Map<String, dynamic>> _weekdayOptions = const [
    {'label': 'Sun', 'value': DateTime.sunday},
    {'label': 'Mon', 'value': DateTime.monday},
    {'label': 'Tue', 'value': DateTime.tuesday},
    {'label': 'Wed', 'value': DateTime.wednesday},
    {'label': 'Thu', 'value': DateTime.thursday},
    {'label': 'Fri', 'value': DateTime.friday},
    {'label': 'Sat', 'value': DateTime.saturday},
  ];

  final Map<int, String> _classTypes = const {
    1: 'TaeKwonDo',
    2: 'Hapkido',
    3: 'Judo',
    4: 'Karate',
    5: 'Other'
  };
  
  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final resp = await _supabase
          .from('goals')
          .select('id, key, title, required_sessions')
          .order('title', ascending: true);
      final list = List<Map<String, dynamic>>.from(resp as List? ?? []);
      setState(() => _goals = list);
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

    Map<String, dynamic> registeredUsers;
    if (registeredUsersText.isNotEmpty) {
      try {
        registeredUsers = Map<String, dynamic>.from(
            jsonDecode(registeredUsersText) as Map<String, dynamic>);
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

    final dateFormatter = DateFormat('MM-dd-yyyy');
    late DateTime startDate;
    try {
      startDate = dateFormatter.parseStrict(date);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid start date')),
      );
      return;
    }

    DateTime? endDate;
    if (recurring) {
      if (_selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least one weekday for recurring classes')),
        );
        return;
      }
      final endDateText = _endDateController.text.trim();
      if (endDateText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an end date for recurring classes')),
        );
        return;
      }
      try {
        endDate = dateFormatter.parseStrict(endDateText);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid end date')),
        );
        return;
      }
      if (endDate.isBefore(startDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')),
        );
        return;
      }
    }

    final List<Map<String, dynamic>> classesToInsert = [];

    if (recurring && endDate != null) {
      // Always add the original class date first
      classesToInsert.add({
        'class_name': className,
        'coach_assigned': coachAssigned,
        'date': dateFormatter.format(startDate),
        'time': time,
        'difficulty': difficulty,
        'reccuring': true,
        'type_of_class': typeOfClass,
        'registered_users': Map<String, dynamic>.from(registeredUsers),
      });

      // Then add all recurring dates that match selected weekdays
      // Start from the day after the original date to avoid duplicates
      DateTime current = startDate.add(const Duration(days: 1));
      while (!current.isAfter(endDate)) {
        if (_selectedWeekdays.contains(current.weekday)) {
          classesToInsert.add({
            'class_name': className,
            'coach_assigned': coachAssigned,
            'date': dateFormatter.format(current),
            'time': time,
            'difficulty': difficulty,
            'reccuring': true,
            'type_of_class': typeOfClass,
            'registered_users': Map<String, dynamic>.from(registeredUsers),
          });
        }
        current = current.add(const Duration(days: 1));
      }
    } else {
      // Non-recurring: just add the single class
      classesToInsert.add({
        'class_name': className,
        'coach_assigned': coachAssigned,
        'date': dateFormatter.format(startDate),
        'time': time,
        'difficulty': difficulty,
        'reccuring': false,
        'type_of_class': typeOfClass,
        'registered_users': Map<String, dynamic>.from(registeredUsers),
      });
    }

    try {
      final insertResp = await _supabase
          .from('classes')
          .insert(classesToInsert)
          .select('id');

      final createdRows = List<Map<String, dynamic>>.from(insertResp as List? ?? []);
      final newClassIds = createdRows
          .map((row) => row['id'])
          .whereType<int>()
          .toList();

      if (_selectedGoalId != null && newClassIds.isNotEmpty) {
        final parsedGoalId = int.tryParse(_selectedGoalId.toString()) ?? _selectedGoalId;
        final goalLinks = newClassIds
            .map((classId) => {
                  'class_id': classId,
                  'goal_id': parsedGoalId,
                })
            .toList();
        await _supabase.from('class_goal_links').insert(goalLinks);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created ${classesToInsert.length} class${classesToInsert.length == 1 ? '' : 'es'} successfully',
          ),
        ),
      );

      _classNameController.clear();
      _coachAssignedController.clear();
      _dateController.clear();
      _timeController.clear();
      _difficultyController.clear();
      _typeOfClassController.clear();
      _registeredUsersController.clear();
      _endDateController.clear();
      setState(() {
        _selectedGoalId = null;
        _selectedDifficulty = null;
        _selectedClassType = null;
        _selectedRecurring = null;
        _selectedWeekdays.clear();
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
                  final user = _supabase.auth.currentUser;
                  if (user == null) return null;

                  // fetch current user's profile
                  final profileResp = await _supabase
                    .from('profiles')
                    .select('id, username, Role')
                    .eq('id', user.id)
                    .limit(1);
                  final profileList = List<Map<String, dynamic>>.from(profileResp as List? ?? []);
                  final profile = profileList.isNotEmpty ? profileList.first : null;

                  // if owner, also fetch all coaches
                  List<Map<String, dynamic>> coaches = [];
                  final role = profile?['Role']?.toString().toLowerCase();
                  if (role == 'owner') {
                  final coachesResp = await _supabase
                    .from('profiles')
                    .select('username, Role')
                    .ilike('Role', 'coach'); // case-insensitive match
                  coaches = List<Map<String, dynamic>>.from(coachesResp as List? ?? []);
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
                    buttonSingleColor: AppColors.primaryBlue,
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
                    buttonSingleColor: AppColors.primaryBlue,

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

              if (_selectedRecurring == true) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Repeat on',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: _weekdayOptions.map((day) {
                    final int value = day['value'] as int;
                    final String label = day['label'] as String;
                    final bool isSelected = _selectedWeekdays.contains(value);
                    return FilterChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeekdays.add(value);
                          } else {
                            _selectedWeekdays.remove(value);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    BottomPicker.date(
                      pickerTitle: const Text(
                        'Select Recurrence End Date',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      minDateTime: DateTime.now(),
                      maxDateTime: DateTime.now().add(const Duration(days: 365 * 3)),
                      onSubmit: (date) {
                        _endDateController.text =
                            '${date.month}-${date.day}-${date.year}';
                        setState(() {});
                      },
                      backgroundColor: AppColors.background,
                    ).show(context);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _endDateController,
                      decoration: _bubbleDecoration('End Date (MM-DD-YYYY)'),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

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
