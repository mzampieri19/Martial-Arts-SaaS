import 'dart:convert';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Colors for UI
class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

// Widget for editing existing classes
class EditClassPage extends StatefulWidget {
  const EditClassPage({super.key});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late List<Map<String, dynamic>> _classes = [];
  late Future<void> _loadFuture;
  late List<Map<String, dynamic>> _coaches = [];

  void initState() {
    // On init, load all classes and coaches
    super.initState();
    _loadFuture = _loadAllClasses();
    _loadCoaches();
  }

  // Method to get all the coaches from Supabase
  Future<void> _loadCoaches() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('username, Role')
          .eq('Role', 'coach');
      // Handle the response and update state if needed
      final list = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
      setState(() {
        _coaches = list;
      }); 
      // You can store coaches in a state variable if needed
    } catch (e) {
      // Show a pop up error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading coaches: $e')),
      );
    }
  }

  // Method to get all the classes from Supabase
  Future<void> _loadAllClasses() async {
    try {
      final response = await _supabase
          .from('classes')
          .select();
      // Handle the response and update state
      final list = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
      setState(() {
        _classes = list;
      });
    } catch (e) {
      // Show a pop up error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading classes: $e')),
      );
    }
  }

  // UI for editing classes would go here
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Classes'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: FutureBuilder(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } 
          return ListView.builder(
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final classItem = _classes[index];
              return ListTile(
                title: Text(classItem['class_name'] ?? 'No Name'),
                subtitle: Text('Class ID: ${classItem['id']}'),
                onTap: () => _showEditDialog(classItem),
              );
            },
          );
        }
      )
    );
  }

  // Show an edit dialog for a class with fields prefilled from classItem
  Future<void> _showEditDialog(Map<String, dynamic> classItem) async {
    final id = classItem['id'];
    // reuse controllers similar to create page
    final TextEditingController nameCtrl = TextEditingController(text: classItem['class_name']?.toString() ?? '');
    final TextEditingController coachCtrl = TextEditingController(text: classItem['coach_assigned']?.toString() ?? '');
    final TextEditingController dateCtrl = TextEditingController(text: classItem['date']?.toString() ?? '');
    final TextEditingController timeCtrl = TextEditingController(text: classItem['time']?.toString() ?? '');
    // difficultyCtrl not needed; use selectedDifficulty instead
    final TextEditingController registeredCtrl = TextEditingController(text: jsonEncode(classItem['registered_users'] ?? {}));
    int? selectedDifficulty = classItem['difficulty'] is int ? classItem['difficulty'] as int : null;
    int? selectedClassType = classItem['type_of_class'] is int ? classItem['type_of_class'] as int : null;
    bool? selectedRecurring = classItem['reccuring'] is bool ? classItem['reccuring'] as bool : null;
    dynamic selectedGoal = null;
    bool saving = false;

    // load goals and coaches for the dialog
    List<Map<String, dynamic>> dialogGoals = [];
    List<Map<String, dynamic>> dialogCoaches = [];
    try {
      final gResp = await _supabase.from('goals').select('id, key, title, required_sessions').order('title', ascending: true);
      dialogGoals = List<Map<String, dynamic>>.from(gResp as List? ?? []);
    } catch (_) {}

    try {
      // only load profiles with Role = 'coach' (case-insensitive)
      final cResp = await _supabase.from('profiles').select('username, Role').ilike('Role', 'coach');
      dialogCoaches = List<Map<String, dynamic>>.from(cResp as List? ?? []);
    } catch (_) {}

    // attempt to load existing class_goal_links selection
    try {
      final linkResp = await _supabase.from('class_goal_links').select('goal_id').eq('class_id', id);
      final links = List<Map<String, dynamic>>.from(linkResp as List? ?? []);
      if (links.isNotEmpty) selectedGoal = links.first['goal_id'];
    } catch (_) {}

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

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          // dedupe coach usernames and goals to avoid duplicate Dropdown items
          final seenCoachNames = <String>{};
          final uniqueCoaches = dialogCoaches.where((c) {
            final name = c['username']?.toString() ?? '';
            if (name.isEmpty) return false;
            if (seenCoachNames.contains(name)) return false;
            seenCoachNames.add(name);
            return true;
          }).toList();

          final seenGoalIds = <dynamic>{};
          final uniqueGoals = dialogGoals.where((g) {
            final id = g['id'];
            if (id == null) return false;
            if (seenGoalIds.contains(id)) return false;
            seenGoalIds.add(id);
            return true;
          }).toList();

          // ensure current coach value exists in uniqueCoaches, otherwise null to avoid assertion
          final coachValue = uniqueCoaches.any((c) => c['username']?.toString() == coachCtrl.text) ? coachCtrl.text : null;

          // ensure selectedGoal exists in uniqueGoals
          final goalValue = uniqueGoals.any((g) => g['id'] == selectedGoal) ? selectedGoal : null;

          return AlertDialog(
            title: const Text('Edit Class'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Class Name')),
                  const SizedBox(height: 8),

                  // Coach dropdown
                  DropdownButtonFormField<String>(
                    value: coachValue,
                    decoration: const InputDecoration(labelText: 'Coach'),
                    items: uniqueCoaches
                        .map((c) => DropdownMenuItem<String>(value: c['username']?.toString() ?? '', child: Text(c['username']?.toString() ?? 'Unknown')))
                        .toList(),
                    onChanged: (v) => setDialogState(() => coachCtrl.text = v ?? ''),
                  ),

                  const SizedBox(height: 8),

                  // Date picker field
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
                        dateCtrl.text =
                            '${date.month}-${date.day}-${date.year}';
                        setState(() {});
                      },
                      backgroundColor: AppColors.background,
                    ).show(context);
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateCtrl,
                      decoration: _bubbleDecoration('Date (MM-DD-YYYY)'),
                    ),
                  ),
                ),

                  const SizedBox(height: 8),

                  // Time field
                  GestureDetector(
                    onTap: () {
                      BottomPicker.time(
                        pickerTitle: const Text(
                          'Select Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        initialTime: Time(hours: 12),
                        onSubmit: (time) {
                          timeCtrl.text =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          setState(() {});
                        },
                        backgroundColor: AppColors.background,
                      ).show(context);
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: _bubbleDecoration('Time (HH:MM)'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Difficulty dropdown
                  DropdownButtonFormField<int>(
                    value: selectedDifficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('Level ${i + 1}'))),
                    onChanged: (v) => setDialogState(() => selectedDifficulty = v),
                  ),
                  const SizedBox(height: 8),

                  // Recurring
                  DropdownButtonFormField<bool>(
                    value: selectedRecurring,
                    decoration: const InputDecoration(labelText: 'Recurring'),
                    items: const [DropdownMenuItem(value: true, child: Text('Yes')), DropdownMenuItem(value: false, child: Text('No'))],
                    onChanged: (v) => setDialogState(() => selectedRecurring = v),
                  ),
                  const SizedBox(height: 8),

                  // Type of class
                  DropdownButtonFormField<int>(
                    value: selectedClassType,
                    decoration: const InputDecoration(labelText: 'Type of Class'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('TaeKwonDo')),
                      DropdownMenuItem(value: 2, child: Text('Hapkido')),
                      DropdownMenuItem(value: 3, child: Text('Judo')),
                      DropdownMenuItem(value: 4, child: Text('Karate')),
                      DropdownMenuItem(value: 5, child: Text('Other')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedClassType = v),
                  ),
                  const SizedBox(height: 8),

                  // Goal selection
                  DropdownButtonFormField<dynamic>(
                    value: goalValue,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: uniqueGoals.map((g) => DropdownMenuItem(value: g['id'], child: Text('${g['title']} (${g['required_sessions'] ?? 0} sessions)'))).toList(),
                    onChanged: (v) => setDialogState(() => selectedGoal = v),
                  ),
                  const SizedBox(height: 8),

                  // Registered users raw JSON
                  TextField(controller: registeredCtrl, decoration: const InputDecoration(labelText: 'Registered Users (JSON)'), maxLines: 3),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a class name')));
                          return;
                        }
                        setDialogState(() => saving = true);

                        final payload = <String, dynamic>{
                          'class_name': nameCtrl.text.trim(),
                          'coach_assigned': coachCtrl.text.trim(),
                          'date': dateCtrl.text.trim(),
                          'time': timeCtrl.text.trim(),
                        };
                        if (selectedDifficulty != null) payload['difficulty'] = selectedDifficulty;
                        if (selectedClassType != null) payload['type_of_class'] = selectedClassType;
                        if (selectedRecurring != null) payload['reccuring'] = selectedRecurring;

                        if (registeredCtrl.text.trim().isNotEmpty) {
                          try {
                            payload['registered_users'] = jsonDecode(registeredCtrl.text.trim());
                          } catch (_) {
                            payload['registered_users'] = registeredCtrl.text.trim();
                          }
                        }

                        final ok = await _saveClassEdits(id, payload);
                        if (ok && selectedGoal != null) {
                          try {
                            // remove existing links for this class then insert the selected goal
                            await _supabase.from('class_goal_links').delete().eq('class_id', id);
                          } catch (_) {}
                          try {
                            await _supabase.from('class_goal_links').insert({'class_id': id, 'goal_id': int.tryParse(selectedGoal.toString()) ?? selectedGoal});
                          } catch (_) {}
                        }

                        setDialogState(() => saving = false);
                        if (ok) Navigator.of(context).pop();
                      },
                child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  // Persist edits to Supabase and update local list on success
  Future<bool> _saveClassEdits(dynamic classId, Map<String, dynamic> payload) async {
    try {
      await _supabase.from('classes').update(payload).eq('id', classId).select();

      // Update local cache
      final idx = _classes.indexWhere((c) => c['id'] == classId);
      if (idx != -1) {
        _classes[idx] = {..._classes[idx], ...payload};
        setState(() {});
      } else {
        // reload all classes as a fallback
        await _loadAllClasses();
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class updated')));
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving class: $e')));
      return false;
    }
  }
}