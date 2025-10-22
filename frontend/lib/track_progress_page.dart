
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';

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
      // preload user progress data (completions + attendance counts)
      await _loadUserProgressData();
      await _getGoalsPerClass(classes);
    } catch (e) {
      // ignore for now
    }
  }

  // Cached user progress state to avoid per-goal RPCs
  // Map of goal_id -> progress (number of classes completed for that goal)
  final Map<int, int> _goalProgress = <int, int>{};
  final Map<int, int> _attendanceByClass = <int, int>{};
  // Cache of per-user per-class marks: key '${goalId}:${classId}' -> true
  final Map<String, bool> _marksCache = <String, bool>{};

  Future<void> _loadUserProgressData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Load completed goals + progress
      final compResp = await Supabase.instance.client
          .from('user_goal_completions')
          .select('goal_id, progress')
          .eq('user_id', userId);
      final comps = List<Map<String, dynamic>>.from(compResp as List? ?? []);
      _goalProgress.clear();
      for (final c in comps) {
        final gid = c['goal_id'];
        final prog = c['progress'] ?? 0;
        if (gid is int) _goalProgress[gid] = (prog is int) ? prog : int.tryParse(prog.toString()) ?? 0;
      }

      // Load attendance counts via RPC once
      final rpcResp = await Supabase.instance.client.rpc('get_user_attendance_counts', params: {'p_user_id': userId});
      final rows = List<Map<String, dynamic>>.from(rpcResp as List? ?? []);
      _attendanceByClass.clear();
      for (final r in rows) {
        final cid = r['class_id'];
        final cnt = r['attended_count'] ?? r['attended'] ?? 0;
        if (cid is int) _attendanceByClass[cid] = cnt as int;
      }

      // Load per-class marks
      try {
        final marksResp = await Supabase.instance.client
            .from('user_goal_class_marks')
            .select('goal_id, class_id')
            .eq('user_id', userId);
        final marks = List<Map<String, dynamic>>.from(marksResp as List? ?? []);
        _marksCache.clear();
        for (final m in marks) {
          final gid = m['goal_id'];
          final cid = m['class_id'];
          if (gid is int && cid is int) _marksCache['${gid}:${cid}'] = true;
        }
      } catch (e) {
        print('Error loading marks: $e');
      }

      // trigger UI update
      setState(() {});
    } catch (e) {
      print('Error loading user progress data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBarWidget(
        title: 'Track Progress',
        showBackButton: true,
      ),
      body: FutureBuilder(
        future: _loadClassesWithGoals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final raw = snapshot.data;
          final classes = (raw is List) ? List<Map<String, dynamic>>.from(raw as List) : <Map<String, dynamic>>[];
          if (classes.isEmpty) return const Center(child: Text('No registered classes found.'));

          // Build unique goals summary from classes' goals
          final Map<int, Map<String, dynamic>> goalsSummary = {};
          for (final c in classes) {
            final goals = c['goals'] as List? ?? [];
            for (final g in goals) {
              final gid = g['id'];
              if (gid is int && !goalsSummary.containsKey(gid)) {
                goalsSummary[gid] = Map<String, dynamic>.from(g as Map<String, dynamic>);
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goal summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.spaceLg),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goals', style: AppConstants.headingSm.copyWith(color: AppConstants.textPrimary)),
                      const SizedBox(height: AppConstants.spaceMd),
                      ...goalsSummary.entries.map((entry) {
                        final gid = entry.key;
                        final g = entry.value;
                        final required = (g['required_sessions'] ?? 0) as int;
                        final progress = _goalProgress[gid] ?? 0;
                        final pct = required > 0 ? (progress / required).clamp(0.0, 1.0) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppConstants.spaceMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(g['title'] ?? g['key'] ?? 'Goal $gid', style: AppConstants.labelLg)),
                                  Text('$progress / $required', style: AppConstants.labelMd),
                                ],
                              ),
                              const SizedBox(height: AppConstants.spaceSm),
                              required > 0 ? LinearProgressIndicator(value: pct) : const SizedBox.shrink(),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spaceLg),

                // Classes list
                ...classes.map((classInfo) {
                  final className = classInfo['class_name'] ?? classInfo['name'] ?? 'Unnamed Class';
                  final goals = classInfo['goals'] as List? ?? [];
                  final cid = classInfo['id'] as int;
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
                    padding: const EdgeInsets.all(AppConstants.spaceMd),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ExpansionTile(
                      title: Text(className, style: AppConstants.headingXs),
                      subtitle: Text('Class ID: $cid', style: AppConstants.bodySm),
                      children: goals.isNotEmpty
                          ? goals.map<Widget>((g) {
                              final goalId = g['id'] as int;
                              final title = g['title'] ?? g['key'] ?? 'Unnamed Goal';
                              final keyStr = '${goalId}:${cid}';
                              final checked = _marksCache[keyStr] == true;
                              final progress = _goalProgress[goalId] ?? 0;
                              return ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(title, style: AppConstants.bodyMd)),
                                    Text('$progress', style: AppConstants.labelMd),
                                  ],
                                ),
                                subtitle: Row(
                                  children: [
                                    Expanded(child: Text('Required: ${g['required_sessions'] ?? 0}')),
                                    Checkbox(
                                      value: checked,
                                      onChanged: (v) async {
                                        final mark = v == true;
                                        await _toggleMark(goalId, cid, mark);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList()
                          : [const ListTile(title: Text('No goals linked for this class'))],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleMark(int goalId, int classId, bool mark) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // optimistic update
    final key = '${goalId}:${classId}';
    _marksCache[key] = mark;
    setState(() {});

    try {
      final resp = await Supabase.instance.client.rpc('toggle_user_goal_mark', params: {
        'p_user_id': userId,
        'p_goal_id': goalId,
        'p_class_id': classId,
        'p_mark': mark,
      });
      print('RPC toggle_user_goal_mark response: $resp');

      // refresh goal progress and marks
      await _loadUserProgressData();
    } catch (e) {
      // Try to show as much info as possible
      String msg = e.toString();
      try {
        // Some Supabase errors include a Map-like body
        if (e is Map && e.containsKey('message')) msg = e['message'].toString();
      } catch (_) {}
      print('RPC toggle_user_goal_mark failed: $msg');
      // revert optimistic change
      _marksCache[key] = !mark;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update mark: $e')));
    }
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

  // (Old helpers `_fetchGoalMeta` and `_toggleGoalCompletion` removed —
  // we now use per-class marks + the RPC `toggle_user_goal_mark` and
  // the `_goalProgress` cache to render progress.)

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