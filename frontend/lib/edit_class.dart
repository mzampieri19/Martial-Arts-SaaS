import 'dart:convert';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/api_service.dart';

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
  late List<Map<String, dynamic>> _classes = [];
  late Future<void> _loadFuture;

  void initState() {
    // On init, load all classes and coaches
    super.initState();
    _loadFuture = _loadAllClasses();
  }

  // Method to get all the classes from API
  Future<void> _loadAllClasses() async {
    try {
      final list = await ApiService.getClasses();
      // Handle the response and update state
      setState(() {
        _classes = List<Map<String, dynamic>>.from(list);
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

  // load goals for the dialog
  List<Map<String, dynamic>> dialogGoals = [];
    try {
      final list = await ApiService.getGoals();
      dialogGoals = List<Map<String, dynamic>>.from(list);
    } catch (_) {}

    // coaches are loaded in the dialog's FutureBuilder based on the viewer's role

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
          // coach/goal values are validated by the create-style UI below

          return AlertDialog(
            title: const Text('Edit Class'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),

                  // Class Name
                  TextField(controller: nameCtrl, decoration: _bubbleDecoration('Class Name')),
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
                          child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                        );
                      }

                      final data = snapshot.data;
                      final profile = data?['profile'] as Map<String, dynamic>?;
                      final coaches = List<Map<String, dynamic>>.from(data?['coaches'] as List? ?? []);
                      final role = profile?['Role']?.toString().toLowerCase();
                      final username = profile?['username']?.toString() ?? '';

                      if (role == 'owner') {
                        // dedupe coach usernames to avoid duplicate DropdownMenuItems
                        final seen = <String>{};
                        final uniqueCoachNames = <String>[];
                        for (final c in coaches) {
                          final name = c['username']?.toString() ?? '';
                          if (name.isEmpty) continue;
                          if (seen.contains(name)) continue;
                          seen.add(name);
                          uniqueCoachNames.add(name);
                        }

                        final coachValue = uniqueCoachNames.contains(coachCtrl.text) ? coachCtrl.text : null;

                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: coachValue,
                              decoration: _bubbleDecoration('Coach Assigned'),
                              items: uniqueCoachNames
                                .map((name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ))
                                .toList(),
                              onChanged: (v) {
                                setDialogState(() {
                                  coachCtrl.text = v ?? '';
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
                      } else {
                        // coach or fallback: show read-only field with their username
                        if (coachCtrl.text.isEmpty && username.isNotEmpty) {
                          coachCtrl.text = username;
                        }
                        return Column(
                          children: [
                            TextField(controller: coachCtrl, readOnly: true, decoration: _bubbleDecoration('Coach Assigned')),
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
                          dateCtrl.text = '${date.month}-${date.day}-${date.year}';
                          setDialogState(() {});
                        },
                        backgroundColor: AppColors.background,
                      ).show(context);
                    },
                    child: AbsorbPointer(child: TextField(controller: dateCtrl, decoration: _bubbleDecoration('Date (MM-DD-YYYY)'))),
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
                          timeCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          setDialogState(() {});
                        },
                        backgroundColor: AppColors.background,
                      ).show(context);
                    },
                    child: AbsorbPointer(child: TextField(controller: timeCtrl, decoration: _bubbleDecoration('Time (HH:MM)'))),
                  ),
                  const SizedBox(height: 20),

                  // Difficulty dropdown
                  DropdownButtonFormField<int>(
                    value: selectedDifficulty,
                    decoration: _bubbleDecoration('Difficulty (1–5)'),
                    items: List.generate(5, (i) => DropdownMenuItem(value: i + 1, child: Text('Level ${i + 1}'))),
                    onChanged: (v) => setDialogState(() => selectedDifficulty = v),
                  ),
                  const SizedBox(height: 20),

                  // Recurring
                  DropdownButtonFormField<bool>(
                    value: selectedRecurring,
                    decoration: _bubbleDecoration('Recurring'),
                    items: const [DropdownMenuItem(value: true, child: Text('Yes')), DropdownMenuItem(value: false, child: Text('No'))],
                    onChanged: (v) => setDialogState(() => selectedRecurring = v),
                  ),
                  const SizedBox(height: 20),

                  // Type of Class
                  DropdownButtonFormField<int>(
                    value: selectedClassType,
                    decoration: _bubbleDecoration('Type of Class'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('TaeKwonDo')),
                      DropdownMenuItem(value: 2, child: Text('Hapkido')),
                      DropdownMenuItem(value: 3, child: Text('Judo')),
                      DropdownMenuItem(value: 4, child: Text('Karate')),
                      DropdownMenuItem(value: 5, child: Text('Other')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedClassType = v),
                  ),
                  const SizedBox(height: 20),

                  // Goal Dropdown
                  DropdownButtonFormField<dynamic>(
                    value: selectedGoal,
                    decoration: _bubbleDecoration('Goal'),
                    items: dialogGoals.map((g) => DropdownMenuItem(value: g['id'], child: Text('${g['title']} (${g['required_sessions'] ?? 0} sessions)'))).toList(),
                    onChanged: (v) => setDialogState(() => selectedGoal = v),
                  ),
                  const SizedBox(height: 30),

                  // Registered Users
                  TextField(controller: registeredCtrl, decoration: _bubbleDecoration('Registered Users (JSON)'), maxLines: 3),
                  const SizedBox(height: 30),

                  // Save button (full width like Create page)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (nameCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all required fields')));
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
                              // Note: Goal linking would need to be handled separately if needed
                              // For now, we're just updating class data

                              setDialogState(() => saving = false);
                              if (ok) Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Persist edits to API and update local list on success
  Future<bool> _saveClassEdits(dynamic classId, Map<String, dynamic> payload) async {
    try {
      await ApiService.updateClass(classId.toString(), payload);

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