
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/api_service.dart';
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

  @override
  void initState() { // Get the info on init
    super.initState();
    _loadGoalsOnInit();
  }

  // Helper to load classes and goals during init
  Future<void> _loadGoalsOnInit() async {
    try {
      final classes = await _getRegisteredClasses(); // Creates a list of classes
      await _loadUserProgressData(); // preload user progress data (completions + attendance counts)
      await _getGoalsPerClass(classes); // Fetch goals for each class and cache advancement values
      await _getAdvancementPerGoal(classes); // Fetch advancement per goal
    } catch (e) {
      print('Error loading goals on init: $e');
    }
  }

  // Cached user progress state
  // Map of goal_id -> progress (number of classes completed for that goal, for the user)
  final Map<int, int> _goalProgress = <int, int>{};
  // Map of class_id -> attendance count (number of times the user attended the class)
  final Map<int, int> _attendanceByClass = <int, int>{};
  // Map of goal_id -> advancement (number of classes completed for that goal, for the user)
  final Map<int, int> _advancementByGoal = <int, int>{};
  // Cache of per-user per-class marks: key '${goalId}:${classId}' -> true
  final Map<String, bool> _marksCache = <String, bool>{};

  // Method to fetch advancement per goal and cache it
  Future<void> _getAdvancementPerGoal(List<Map<String, dynamic>> classes) async {
    // Check if user is logged in
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final goals = await ApiService.getGoals();
      for (final g in goals) {
        final gid = g['id'];
        final advRaw = g['advancement'];
        final advVal = (advRaw is int) ? advRaw : int.tryParse(advRaw?.toString() ?? '') ?? 0;
        if (gid is int) _advancementByGoal[gid] = advVal;
      }
    } catch (e) {
      print('Error loading advancement data: $e');
    }
  }

  // Load user progress data: completed goals + attendance counts + per-class marks
  Future<void> _loadUserProgressData() async {
    // Check if user is logged in
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Load all progress data via API
      final progressData = await ApiService.getUserProgress(userId);
      
      // Load completed goals + progress
      final comps = progressData['goalProgress'] as List? ?? [];
      _goalProgress.clear();
      for (final c in comps) {
        final gid = c['goal_id'];
        final prog = c['progress'] ?? 0;
        if (gid is int) _goalProgress[gid] = (prog is int) ? prog : int.tryParse(prog.toString()) ?? 0;
      }

      // Load attendance counts via RPC once
      final rows = progressData['attendance'] as List? ?? [];
      _attendanceByClass.clear();
      for (final r in rows) {
        final cid = r['class_id'];
        final cnt = r['attended_count'] ?? r['attended'] ?? 0;
        if (cid is int) _attendanceByClass[cid] = cnt as int;
      }

      // Load per-class marks
      final marks = progressData['marks'] as List? ?? [];
      _marksCache.clear();
      for (final m in marks) {
        final gid = m['goal_id'];
        final cid = m['class_id'];
        if (gid is int && cid is int) _marksCache['$gid:$cid'] = true;
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
        future: _loadClassesWithGoals(), // Load classes and the goals for the user
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
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.spaceLg),

                // Classes list
                ...classes.map((classInfo) {
                  final className = classInfo['class_name'] ?? classInfo['name'] ?? 'Unnamed Class';
                  final goals = classInfo['goals'] as List? ?? [];
                  final cid = classInfo['id'] as int;
                  final date = classInfo['date'] as String? ?? 'Unknown Date';
                  final time = classInfo['time'] as String? ?? 'Unknown Time';
                  final coach = classInfo['coach_name'] as String? ?? 'Unknown Coach';
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date: $date', style: AppConstants.bodySm),
                          Text('Time: $time', style: AppConstants.bodySm),
                          Text('Coach: $coach', style: AppConstants.bodySm),
                        ],
                      ),
                      children: goals.isNotEmpty
                          ? goals.map<Widget>((g) {
                              final goalId = g['id'] as int;
                              final title = g['title'] ?? g['key'] ?? 'Unnamed Goal';
                              final keyStr = '$goalId:$cid';
                              final checked = _marksCache[keyStr] == true;
                              final adv = _advancementByGoal[goalId] ?? 0;
                              return ListTile(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(title, style: AppConstants.bodyMd)),
                                    Text('Advancement: $adv', style: AppConstants.labelMd),
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
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // Toggle check mark for goal completion in a class
  Future<void> _toggleMark(int goalId, int classId, bool mark) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // optimistic update
    final key = '$goalId:$classId';
    final oldMarkValue = _marksCache[key] ?? false;
    // update mark cache optimistically
    _marksCache[key] = mark;
    // also update goal progress optimistically so the UI feels responsive
    final oldProgress = _goalProgress[goalId] ?? 0;
    _goalProgress[goalId] = mark ? oldProgress + 1 : (oldProgress > 0 ? oldProgress - 1 : 0);
    setState(() {});

    try {
      await ApiService.toggleMark(userId, goalId, classId, mark);

      // refresh goal progress and marks from DB to ensure canonical state
      await _loadUserProgressData();
    } catch (e) {
      print('Failed to toggle mark: $e');
      // revert optimistic change
      _marksCache[key] = oldMarkValue;
      _goalProgress[goalId] = oldProgress;
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update mark: ${e.toString()}')),
        );
      }
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
        final allClasses = await ApiService.getClasses();
        classRow = allClasses.firstWhere(
          (c) => c['id'] == classId,
          orElse: () => {},
        ) as Map<String, dynamic>?;
      } catch (_) {
        classRow = null;
      }

      final className = (classRow != null && classRow['class_name'] != null)
          ? classRow['class_name']
          : reg['class_name'];

      // Try to pull schedule/coach info from the nested `classes` object returned
      // when `student_classes` select included it.
      String? dateFromReg;
      String? timeFromReg;
      String? coachFromReg;
      if (reg.containsKey('classes')) {
        try {
          final nested = reg['classes'];
          if (nested is Map) {
            dateFromReg = nested['date']?.toString();
            timeFromReg = nested['time']?.toString();
            coachFromReg = nested['coach_assigned']?.toString();
          }
        } catch (_) {}
      }

      // Fetch linked goals in one nested query (returns nested `goals` object/array depending on PostgREST)
      List<Map<String, dynamic>> goalsList = [];
      try {
        final linksResp = await ApiService.getClassGoalLinks(classId.toString());

        final links = List<Map<String, dynamic>>.from(linksResp);
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
              final allGoals = await ApiService.getGoals();
              goalResp = allGoals.firstWhere(
                (g) => g['id'] == l['goal_id'],
                orElse: () => {},
              ) as Map<String, dynamic>?;
            } catch (_) {}
          }

          if (goalResp != null && goalResp.isNotEmpty) goalsList.add(goalResp);
        }
      } catch (e) {
        // log to help debug why goals may be missing
        // ignore errors but print for debugging during development
        print('Error fetching goals for class $classId: $e');
      }

      // Debug: how many goals found for this class
      print('Class $classId linked goals count: ${goalsList.length}, advancement ${_advancementByGoal[classId] ?? 0}');

      results.add({
        'registration_id': registrationId,
        'id': classId,
        'class_name': className ?? 'Unnamed Class',
        'date': dateFromReg ?? reg['date'],
        'time': timeFromReg ?? reg['time'],
        'coach_name': coachFromReg ?? reg['coach_assigned'] ?? reg['coach_name'],
        'goals': goalsList,
        'advancement': _advancementByGoal[classId] ?? 0,
      });
    }

    return results;
  }

  // Fetch registered classes for the user from API, returns a list of classes
  Future<List<Map<String, dynamic>>> _getRegisteredClasses() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view your account.')),
        );
      }
      return [];
    }

    // Request the nested `classes` row to include schedule/coach fields when available
    final response = await ApiService.getStudentClasses(userId);
    final classes = List<Map<String, dynamic>>.from(response);
    return classes;
  }

  // Fetch goals for each class and cache advancement values
  Future<void> _getGoalsPerClass(List<Map<String, dynamic>> classes) async {
    for (final cls in classes) {
      final classId = cls['id'];
      try {
        final linksResp = await ApiService.getClassGoalLinks(classId.toString());

        final links = List<Map<String, dynamic>>.from(linksResp);
        for (final l in links) {
          dynamic nested = l['goals'];
          Map<String, dynamic>? goalResp;
          if (nested is List && nested.isNotEmpty) {
            goalResp = Map<String, dynamic>.from(nested.first as Map);
          } else if (nested is Map) {
            goalResp = Map<String, dynamic>.from(nested);
          } else if (l.containsKey('goal_id')) {
            try {
              final allGoals = await ApiService.getGoals();
              goalResp = allGoals.firstWhere(
                (g) => g['id'] == l['goal_id'],
                orElse: () => {},
              ) as Map<String, dynamic>?;
            } catch (_) {}
          }

          if (goalResp != null && goalResp.isNotEmpty) {
            try {
              final advRaw = goalResp['advancement'];
              final advVal = (advRaw is int) ? advRaw : int.tryParse(advRaw?.toString() ?? '') ?? 0;
              final gidParsed = goalResp['id'];
              if (gidParsed is int) _advancementByGoal[gidParsed] = advVal;
            } catch (_) {}
          }
        }
      } catch (e) {
        print('Error fetching goals for class $classId: $e');
      }
    }
  }
}