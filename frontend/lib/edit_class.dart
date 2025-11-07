import 'dart:convert';
import 'package:bottom_picker/bottom_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/components/classes_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'components/qr_code_display.dart';

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

  void initState() {
    // On init, load all classes and coaches
    super.initState();
    _loadFuture = _loadAllClasses();
  }

  // Method to get all the classes from Supabase
  // Filters by role: Owners see all classes, Coaches only see their assigned classes
  Future<void> _loadAllClasses() async {
    try {
      // First, get the current user's profile to check their role
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view classes')),
        );
        return;
      }

      final profileResp = await _supabase
          .from('profiles')
          .select('Role, username')
          .eq('id', user.id)
          .maybeSingle();

      final role = profileResp?['Role']?.toString().toLowerCase();
      final username = profileResp?['username']?.toString() ?? '';

      // Build the query - filter by coach_assigned if user is a coach
      List<Map<String, dynamic>> list;
      
      if (role == 'coach' && username.isNotEmpty) {
        // Coach: only show classes where coach_assigned matches their username
        // Fetch all classes first, then filter client-side to avoid type issues
        final response = await _supabase
            .from('classes')
            .select('*, join_token');
        final allClasses = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
        
        // Filter to only classes where coach_assigned matches username
        list = allClasses.where((classItem) {
          final coachAssigned = classItem['coach_assigned']?.toString().trim() ?? '';
          return coachAssigned.toLowerCase() == username.toLowerCase().trim();
        }).toList();
      } else {
        // Owner or other roles: show all classes (no filter)
        final response = await _supabase
            .from('classes')
            .select('*, join_token');
        list = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
      }

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
          return ClassesList(
            classes: _classes,
            onTap: (classItem) async {
              await _showEditDialog(classItem);
            }, onRegister: (p1) {  }, 
            onUnregister: (p1) {  }, 
            onEdit: (p1) {  }, 
            enableActions: true,
            disableInnerScroll: false,
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
      final gResp = await _supabase.from('goals').select('id, key, title, required_sessions').order('title', ascending: true);
      dialogGoals = List<Map<String, dynamic>>.from(gResp as List? ?? []);
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
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          // coach/goal values are validated by the create-style UI below

          return Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Class',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                  const SizedBox(height: 8),

                  // Class Name
                  TextField(controller: nameCtrl, decoration: _bubbleDecoration('Class Name')),
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
                          .ilike('Role', 'coach');
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

                  // QR Code Display Section
                  const Divider(height: 32),
                  Builder(
                    builder: (context) {
                      // Debug: Check if join_token exists
                      final joinToken = classItem['join_token'];
                      print('DEBUG: join_token value: $joinToken');
                      print('DEBUG: join_token type: ${joinToken.runtimeType}');
                      
                      if (joinToken != null && joinToken.toString().isNotEmpty) {
                        return QRCodeDisplay(
                          joinToken: joinToken.toString(),
                          className: nameCtrl.text.isNotEmpty ? nameCtrl.text : classItem['class_name']?.toString(),
                          size: 200,
                        );
                      } else {
                        // Show a message if join_token is missing
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'No QR Code Available',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'This class does not have a join_token.\nGenerate one in your database.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 20),

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
                              if (ok && selectedGoal != null) {
                                try {
                                  await _supabase.from('class_goal_links').delete().eq('class_id', id);
                                } catch (_) {}
                                try {
                                  await _supabase.from('class_goal_links').insert({'class_id': id, 'goal_id': int.tryParse(selectedGoal.toString()) ?? selectedGoal});
                                } catch (_) {}
                              }

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
                  const SizedBox(height: 24),
                        ],
                      ),
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