import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:frontend/main.dart' show AppColors;

class TrackProgressPage extends StatefulWidget {
  const TrackProgressPage({super.key});

  @override
  State<TrackProgressPage> createState() => _TrackProgressPageState();
}

class _TrackProgressPageState extends State<TrackProgressPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  /// Results to display
  List<ClassProgress> _items = [];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<List<Map<String, dynamic>>> _fetchGoalsForClass(dynamic classId, int attendedForClass) async {
  // Fetch canonical goals for the class from a deduplicated server-side view
  final resp = await _supabase
    .from('view_unique_class_goals')
    .select('id, title, description, required_sessions, sort_order')
    .eq('class_id', classId)
    .order('sort_order', ascending: true);

    final list = List<Map<String, dynamic>>.from(resp as List? ?? []);

    if (list.isEmpty) return list;

    // Fetch the current user's completion rows for these goals to avoid duplicates
    final user = _supabase.auth.currentUser;
    Map<dynamic, Map<String, dynamic>> progressMap = {};
    if (user != null) {
      final goalIds = list.map((g) => g['id']).toList();
    final progResp = await _supabase
      .from('user_goal_progress')
      .select('goal_id, completed_at')
      .eq('user_id', user.id)
      .filter('goal_id', 'in', '(${goalIds.join(',')})');

      final progList = List<Map<String, dynamic>>.from(progResp as List? ?? []);
      for (final p in progList) {
        progressMap[p['goal_id']] = p;
      }
    }

    // Attach attended count and completion info
    for (final g in list) {
      g['_attended_for_class'] = attendedForClass;
      final pid = g['id'];
      final p = progressMap[pid];
      g['completed'] = p != null;
      g['completed_at'] = p != null ? p['completed_at'] : null;
      // Placeholder for contributing attendance rows; will be filled by caller if needed
      g['_attendance_rows'] = <Map<String, dynamic>>[];
    }

    return list;
  }

  /// Fetch attendance rows for a given class and user, optionally limited to rows
  /// that contributed to goals. Returns list of attendance rows with date, class_name, duration.
  Future<List<Map<String, dynamic>>> _fetchAttendanceRowsForClass(dynamic classId, {int? limit}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    // Join attendance with classes to get class name and other metadata
  // Note: select attendance rows joined with classes to get class name
  final rowsRaw = await _supabase
        .from('user_class_attendance')
        .select('attended_at, duration_minutes, notes, classes(class_name)')
        .eq('user_id', user.id)
        .eq('class_id', classId)
        .order('attended_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(rowsRaw as List? ?? []);
  final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      final attendedAt = r['attended_at'] != null
          ? DateTime.tryParse(r['attended_at'].toString())?.toLocal()
          : null;
      final className = (r['classes'] != null && (r['classes'] is Map)) ? r['classes']['class_name'] : null;
      out.add({
        'attended_at': attendedAt,
        'class_name': className ?? 'Class',
        'duration_minutes': r['duration_minutes'],
        'notes': r['notes'],
      });
      if (limit != null && out.length >= limit) break;
    }

    return out;
  }

  Future<void> _toggleGoalCompletion(dynamic goalId, dynamic classId, bool complete) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (complete) {
      try {
        await _supabase.from('user_goal_progress').insert({
          'user_id': user.id,
          'goal_id': goalId,
        });
      } catch (_) {
        // ignore duplicate
      }
    } else {
      await _supabase
          .from('user_goal_progress')
          .delete()
          .eq('user_id', user.id)
          .eq('goal_id', goalId);
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _error = 'Please sign in to see your progress.';
        _loading = false;
      });
      return;
    }

    try {
      // Call the RPC to get aggregated stats for this user
      final rpcResponse = await _supabase.rpc('get_user_class_stats', params: {
        'p_user_id': user.id,
      });

      final rows = List<Map<String, dynamic>>.from(rpcResponse as List? ?? []);

      if (rows.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      // Get class metadata
      final classIds = rows.map((r) => r['class_id']).toList();
      final classesResponse = await _supabase
          .from('classes')
          .select('id, class_name, difficulty, type_of_class, target_sessions')
          .filter('id', 'in', '(${classIds.join(',')})');

      final classes = List<Map<String, dynamic>>.from(classesResponse as List? ?? []);
      final Map<dynamic, Map<String, dynamic>> classMap = {for (final c in classes) c['id']: c};

      final List<ClassProgress> items = [];
      for (final r in rows) {
        final cid = r['class_id'];
        final cls = classMap[cid];
        final className = cls != null ? (cls['class_name']?.toString() ?? 'Unnamed class') : 'Class $cid';

        int targetSessions = 8;
        if (cls != null) {
          final ts = cls['target_sessions'];
          if (ts != null) {
            try { targetSessions = (ts as num).toInt(); } catch (_) { targetSessions = int.tryParse(ts.toString()) ?? targetSessions; }
          } else {
            final diff = cls['difficulty'];
            int difficulty = 0;
            if (diff != null) {
              try { difficulty = (diff as num).toInt(); } catch (_) { difficulty = int.tryParse(diff.toString()) ?? 0; }
            }
            targetSessions = 8 + (difficulty * 4);
          }
        }

        final attended = (r['attended_count'] as num).toInt();
        final progress = targetSessions > 0 ? (attended / targetSessions).clamp(0.0, 1.0) : 0.0;

        items.add(ClassProgress(
          classId: cid,
          className: className,
          attendedCount: attended,
          targetSessions: targetSessions,
          progressPercent: progress,
          weeksActive: (r['weeks_active'] as num?)?.toInt() ?? 0,
          avgPerWeek: (r['avg_per_week'] as num?)?.toDouble() ?? 0.0,
          last30DaysCount: (r['last_30_days_count'] as num?)?.toInt() ?? 0,
          firstAttendedAt: r['first_attended_at'] != null ? DateTime.tryParse(r['first_attended_at'].toString()) : null,
          lastAttendedAt: r['last_attended_at'] != null ? DateTime.tryParse(r['last_attended_at'].toString()) : null,
        ));
      }

      items.sort((a, b) => a.className.compareTo(b.className));
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load progress: $e'; _loading = false; });
    }
  }

  Future<void> _showClassDetails(ClassProgress it) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final attResponse = await _supabase
        .from('user_class_attendance')
        .select('attended_at, session_type, duration_minutes, notes')
        .eq('user_id', user.id)
        .eq('class_id', it.classId)
        .order('attended_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(attResponse as List? ?? []);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (rows.isEmpty) const Text('No attendance records.'),
                if (rows.isNotEmpty)
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final r = rows[index];
                        final attendedAt = r['attended_at'] != null
                            ? DateTime.tryParse(r['attended_at'].toString())?.toLocal()
                            : null;
                        final sessionType = r['session_type']?.toString() ?? '—';
                        final notes = r['notes']?.toString() ?? '';

                        final dateStr = attendedAt != null
                            ? DateFormat.yMMMd().add_jm().format(attendedAt)
                            : 'Unknown date';
                        final durationStr = (r['duration_minutes'] != null && r['duration_minutes'].toString().isNotEmpty)
                            ? '${r['duration_minutes']} min'
                            : '—';

                        return ListTile(
                          title: Text(dateStr),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Type: $sessionType • Duration: $durationStr'),
                              if (notes.isNotEmpty) Text('Notes: $notes'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  double _overallProgress() {
    if (_items.isEmpty) return 0.0;
    // Simple unweighted average of each class progress
    return _items.map((i) => i.progressPercent).reduce((a, b) => a + b) /
        _items.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        title: Text(
          'Track Progress',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProgress,
            color: AppColors.primary,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? const Center(child: Text('No attendance records found.'))
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Card(
                              color: AppColors.surfaceLight,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Overall Progress',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark),
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _overallProgress(),
                                        minHeight: 12,
                                        backgroundColor: Colors.white,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        '${(_overallProgress() * 100).toStringAsFixed(0)}% complete • ${_items.length} class(es)',
                                        style: TextStyle(
                                          color: AppColors.textSubtle,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final it = _items[index];
                                  return InkWell(
                                    onTap: () => _showClassDetails(it),
                                    child: Card(
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    it.className,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.textDark,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                    '${(it.progressPercent * 100).toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      color: AppColors.textDark,
                                                    )),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: it.progressPercent,
                                                minHeight: 8,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                                'Attended: ${it.attendedCount} / ${it.targetSessions} sessions',
                                                style: TextStyle(
                                                  color: AppColors.textSubtle,
                                                )),
                                            const SizedBox(height: 8),
                                            FutureBuilder<List<Map<String, dynamic>>>(
                                              future: Future.wait([
                                                _fetchGoalsForClass(it.classId, it.attendedCount),
                                                _fetchAttendanceRowsForClass(it.classId),
                                              ]).then((parts) {
                                                final dynamic p0 = parts[0];
                                                final dynamic p1 = parts[1];
                                                final goals = List<Map<String, dynamic>>.from(p0 as List? ?? []);
                                                final attendance = List<Map<String, dynamic>>.from(p1 as List? ?? []);
                                                // Attach attendance rows to each goal so UI can show which classes contributed
                                                for (final g in goals) {
                                                  // For now we attach all attendance rows for the class; later you can refine to map specific rows to goals
                                                  g['_attendance_rows'] = attendance;
                                                  // Compute attended-for-goal as number of attendance rows for this class
                                                  g['_attended_for_goal'] = attendance.length;
                                                }

                                                // Client-side dedupe fallback: if DB still has duplicate titles, collapse them
                                                final Map<String, Map<String, dynamic>> unique = {};
                                                String _normalizeKey(Object? o) {
                                                  final s = (o ?? '').toString();
                                                  // collapse whitespace and lower-case
                                                  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
                                                  return t;
                                                }

                                                for (final g in goals) {
                                                  final key = _normalizeKey(g['title']);
                                                  if (key.isEmpty) continue;
                                                  if (!unique.containsKey(key)) {
                                                    unique[key] = Map<String, dynamic>.from(g);
                                                  } else {
                                                    final ex = unique[key]!;
                                                    // prefer completed state
                                                    ex['completed'] = (ex['completed'] == true) || (g['completed'] == true);
                                                    ex['completed_at'] = ex['completed_at'] ?? g['completed_at'];
                                                    // merge attendance rows (keep unique by attended_at)
                                                    final exAtt = List<Map<String, dynamic>>.from(ex['_attendance_rows'] as List? ?? []);
                                                    final gAtt = List<Map<String, dynamic>>.from(g['_attendance_rows'] as List? ?? []);
                                                    final merged = {...{for (var a in exAtt) (a['attended_at']?.toString() ?? a.hashCode.toString()): a}};
                                                    for (final a in gAtt) {
                                                      merged[a['attended_at']?.toString() ?? a.hashCode.toString()] = a;
                                                    }
                                                    ex['_attendance_rows'] = merged.values.toList();
                                                    ex['_attended_for_goal'] = (ex['_attendance_rows'] as List).length;
                                                    unique[key] = ex;
                                                  }
                                                }

                                                return unique.values.toList();
                                              }),
                                              builder: (context, snap) {
                                                if (snap.connectionState == ConnectionState.waiting) return const SizedBox();
                                                final goals = snap.data ?? [];
                                                if (goals.isEmpty) return const SizedBox();
                                                  return Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: goals.map((g) {
                                                      final goalId = g['id'];
                                                      final title = g['title'] ?? 'Goal';
                                                      final required = (g['required_sessions'] as num?)?.toInt() ?? 0;
                                                      final completed = g['completed'] == true;
                                                      final attendedForGoal = (g['_attended_for_class'] as int? ?? 0);
                                                      final goalProgress = required > 0
                                                          ? (attendedForGoal / required).clamp(0.0, 1.0)
                                                          : 0.0;

                                                      final attendanceRows = List<Map<String, dynamic>>.from(g['_attendance_rows'] as List? ?? []);

                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              Expanded(child: Text(title, style: TextStyle(color: AppColors.textDark))),
                                                              IconButton(
                                                                onPressed: () async {
                                                                  await _toggleGoalCompletion(goalId, it.classId, !completed);
                                                                  // Refresh
                                                                  setState(() {});
                                                                },
                                                                icon: Icon(completed ? Icons.check_circle : Icons.circle_outlined, color: completed ? AppColors.primary : AppColors.textSubtle),
                                                              ),
                                                            ],
                                                          ),
                                                          if (required > 0)
                                                            Padding(
                                                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius: BorderRadius.circular(6),
                                                                    child: LinearProgressIndicator(
                                                                      value: goalProgress,
                                                                      minHeight: 6,
                                                                      backgroundColor: Colors.grey.shade200,
                                                                      color: AppColors.primary,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 4),
                                                                  Text('${(goalProgress*100).toStringAsFixed(0)}% • ${attendedForGoal}/${required} sessions', style: TextStyle(color: AppColors.textSubtle, fontSize: 12)),
                                                                ],
                                                              ),
                                                            ),
                                                          // Show contributing attendance rows for this goal
                                                          if (attendanceRows.isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: attendanceRows.take(3).map((ar) {
                                                                  final attendedAt = ar['attended_at'] as DateTime?;
                                                                  final dateStr = attendedAt != null ? DateFormat.yMMMd().add_jm().format(attendedAt) : 'Unknown';
                                                                  final cname = ar['class_name']?.toString() ?? 'Class';
                                                                  final duration = ar['duration_minutes'] != null ? '${ar['duration_minutes']} min' : '—';
                                                                  return Padding(
                                                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                                    child: Text('$dateStr — $cname • $duration', style: TextStyle(color: AppColors.textSubtle, fontSize: 12)),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                            ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}

/// Simple data holder for what we show on the screen
class ClassProgress {
  final dynamic classId;
  final String className;
  final int attendedCount;
  final int targetSessions;
  final double progressPercent; // 0.0 - 1.0
  final int weeksActive;
  final double avgPerWeek;
  final int last30DaysCount;
  final DateTime? firstAttendedAt;
  final DateTime? lastAttendedAt;

  ClassProgress({
    required this.classId,
    required this.className,
    required this.attendedCount,
    required this.targetSessions,
    required this.progressPercent,
    this.weeksActive = 0,
    this.avgPerWeek = 0.0,
    this.last30DaysCount = 0,
    this.firstAttendedAt,
    this.lastAttendedAt,
  });
}