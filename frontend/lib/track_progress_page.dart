
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrackingProgressPage extends StatefulWidget {
  @override
  _TrackingProgressPageState createState() => _TrackingProgressPageState();
}

class _TrackingProgressPageState extends State<TrackingProgressPage> {

  // This page loads the user's registered classes and the goals associated with each of those classes.

  // Once loaded, display each class and goal and give the user the ability to check the completed classes.

  // Once a class is checked as completed, update the progress toward the associated goals.

  // Show a progress bar for each goal indicating how many classes have been completed toward that goal.

  void initState() {
    super.initState();
    _loadGoalsOnInit();
  }

  // Helper to load classes and goals during init
  Future<void> _loadGoalsOnInit() async {
    try {
      final classes = await _getRegisteredClasses();
      await _getGoalsPerClass(classes);
    } catch (e) {
      // ignore for now
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking Progress'),
      ),
      body: Center(
        // Show the registered classes and their associated goals here
        child: FutureBuilder(
          future: _loadClassesWithGoals(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
              return Text('No registered classes found.');
            } else {
              final raw = snapshot.data;
              final classes = (raw is List)
                  ? List<Map<String, dynamic>>.from(raw as List)
                  : <Map<String, dynamic>>[];

              return ListView.builder(
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final classInfo = classes[index];
                  final className = classInfo['class_name'] ?? classInfo['name'] ?? 'Unnamed Class';
                  final goals = classInfo['goals'] as List? ?? [];

                  return ExpansionTile(
                    title: Text(className),
                    subtitle: Text('Class ID: ${classInfo['id']}'),
                    children: goals.isNotEmpty
                        ? goals.map<Widget>((g) {
                            final goalId = g['id'];
                            final title = g['title'] ?? g['key'] ?? 'Unnamed Goal';
                            return FutureBuilder<Map<String, dynamic>>(
                              future: _fetchGoalMeta(goalId, g['required_sessions'] ?? 0),
                              builder: (context, snap) {
                                final loading = snap.connectionState == ConnectionState.waiting;
                                final meta = snap.data ?? {};
                                final completed = meta['completed'] == true;
                                final attended = meta['attended'] ?? 0;
                                final required = (g['required_sessions'] ?? 0) as int;
                                double progress = 0.0;
                                if (required > 0) {
                                  progress = (attended / required).clamp(0.0, 1.0);
                                }

                                return CheckboxListTile(
                                  value: completed,
                                  title: Text(title),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(loading ? 'Loading progress...' : '$attended / $required sessions'),
                                      const SizedBox(height: 6),
                                      required > 0
                                          ? LinearProgressIndicator(value: progress)
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                  onChanged: (v) => _toggleGoalCompletion(goalId, v == true),
                                );
                              },
                            );
                          }).toList()
                        : [ListTile(title: Text('No goals linked for this class'))],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  // Loads registered classes and adds class name + associated goals
  Future<List<Map<String, dynamic>>> _loadClassesWithGoals() async {
    final registered = await _getRegisteredClasses();
    if (registered.isEmpty) return [];

    final List<Map<String, dynamic>> results = [];

    for (final reg in registered) {
      // student_classes rows may include a `class_id` column that points to the classes table.
      // Use that when available; otherwise fall back to the registration row's id.
      final registrationId = reg['id'];
      final classId = reg.containsKey('class_id') ? reg['class_id'] : registrationId;

      // Fetch class details
      Map<String, dynamic>? classRow;
      try {
        classRow = await Supabase.instance.client
            .from('classes')
            .select('id, class_name')
            .eq('id', classId)
            .maybeSingle();
      } catch (_) {
        classRow = null;
      }

      final className = (classRow != null && classRow['class_name'] != null)
          ? classRow['class_name']
          : reg['class_name'];

      // Fetch linked goals in one nested query (returns nested `goals` object/array depending on PostgREST)
      List<Map<String, dynamic>> goalsList = [];
      try {
        final linksResp = await Supabase.instance.client
            .from('class_goal_links')
            .select('goal_id, goals(id, key, title, required_sessions)')
            .eq('class_id', classId);

        final links = List<Map<String, dynamic>>.from(linksResp as List? ?? []);
        for (final l in links) {
          // Supabase/PostgREST may return the related row as a map or an array under the 'goals' key.
          dynamic nested = l['goals'];
          Map<String, dynamic>? goalResp;
          if (nested is List && nested.isNotEmpty) {
            goalResp = Map<String, dynamic>.from(nested.first as Map);
          } else if (nested is Map) {
            goalResp = Map<String, dynamic>.from(nested);
          } else if (l.containsKey('goal_id')) {
            // fallback: fetch the goal row directly
            try {
              final g = await Supabase.instance.client
                  .from('goals')
                  .select('id, key, title, required_sessions')
                  .eq('id', l['goal_id'])
                  .maybeSingle();
              if (g != null) goalResp = Map<String, dynamic>.from(g as Map);
            } catch (_) {}
          }

          if (goalResp != null) goalsList.add(goalResp);
        }
      } catch (e) {
        // log to help debug why goals may be missing
        // ignore errors but print for debugging during development
        print('Error fetching goals for class $classId: $e');
      }

      // Debug: how many goals found for this class
      print('Class $classId linked goals count: ${goalsList.length}');

      results.add({
        'registration_id': registrationId,
        'id': classId,
        'class_name': className ?? 'Unnamed Class',
        'goals': goalsList,
      });
    }

    return results;
  }

  // Fetch goal metadata: whether completed and how many sessions attended across linked classes
  Future<Map<String, dynamic>> _fetchGoalMeta(int goalId, int requiredSessions) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return {'completed': false, 'attended': 0};

    bool completed = false;
    int attendedCount = 0;

    try {
      // Check completion
      final comp = await Supabase.instance.client
          .from('user_goal_completions')
          .select('id')
          .eq('user_id', userId)
          .eq('goal_id', goalId)
          .maybeSingle();
      completed = comp != null;
    } catch (_) {}

    try {
      // Count attendance rows for classes linked to this goal
      // First fetch class_ids linked to this goal
      final links = await Supabase.instance.client
          .from('class_goal_links')
          .select('class_id')
          .eq('goal_id', goalId);
      final classIds = List<Map<String, dynamic>>.from(links as List? ?? [])
          .map((e) => e['class_id'])
          .whereType<int>()
          .toList();

      if (classIds.isNotEmpty) {
        final resp = await Supabase.instance.client.rpc('get_user_attendance_counts', params: {
          'p_user_id': userId,
        });
        // rpc returns list of {class_id, attended_count}
        final rows = List<Map<String, dynamic>>.from(resp as List? ?? []);
        for (final r in rows) {
          final cid = r['class_id'];
          final ccount = r['attended_count'] ?? r['attended'] ?? 0;
          if (classIds.contains(cid)) attendedCount += (ccount as int);
        }
      }
    } catch (e) {
      // ignore
    }

    return {'completed': completed, 'attended': attendedCount, 'required': requiredSessions};
  }

  // Toggle completion: insert or delete a user_goal_completions row
  Future<void> _toggleGoalCompletion(int goalId, bool completed) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in')));
      return;
    }
    setState(() {});

    final parsedGoalId = int.tryParse(goalId.toString()) ?? goalId;

    if (completed) {
      try {
        final resp = await Supabase.instance.client
            .from('user_goal_completions')
            .insert({'user_id': userId, 'goal_id': parsedGoalId}).select();
        final inserted = List<Map<String, dynamic>>.from(resp as List? ?? []);
        if (inserted.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to mark goal complete')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to mark goal complete: $e')));
      }
    } else {
      try {
        final resp = await Supabase.instance.client
            .from('user_goal_completions')
            .delete()
            .match({'user_id': userId, 'goal_id': parsedGoalId}).select();
        final deleted = List<Map<String, dynamic>>.from(resp as List? ?? []);
        if (deleted.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to unmark goal completion')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unmark goal completion: $e')));
      }
    }

    // ensure UI updates to reflect actual state
    setState(() {});
  }

  // Fetch registered classes for the user from Supabase, returns a list of classes
  Future<List<Map<String, dynamic>>> _getRegisteredClasses() async {
    // Fetch registered classes for the user from the supabase

    final user_id = Supabase.instance.client.auth.currentUser?.id;
    if (user_id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view your account.')),
      );
      return [];
    }

    final response = await Supabase.instance.client
      .from('student_classes')
      .select()
      .eq('profile_id', user_id); 

      final classes = List<Map<String, dynamic>>.from(response as List? ?? []);
      // Return classes
      return classes;
  }

  // Fetch goals for each class and process them
  Future<Map<String, dynamic>?> _getGoalsPerClass(List<Map<String, dynamic>> classes) async {
  // Fetch goals for each class from the supabase
    for (var class_index in classes) {
      final classId = class_index['id'];
      final response = await Supabase.instance.client
        .from('class_goal_links')
        .select()
        .eq('class_id', classId); // Assuming classId is available

      final goals = List<Map<String, dynamic>>.from(response as List? ?? []);
      // Process goals for the class
      for (var goal in goals) {
        final goalId = goal['goal_id'];
        // Fetch goal details if needed
        final goalDetails = await Supabase.instance.client
          .from('goals')
          .select()
          .eq('id', goalId)
          .maybeSingle();

        // Store goals details as needed
        if (goalDetails != null) {
          print('Class ID: $classId, Goal: ${goalDetails['title']}');
        }
        return goalDetails;
      }
    }
    return null;
  }
}