import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      // Fetch attendance rows for this user from the attendance table.
      // Table name: `user_class_attendance` (one row per attended class session).
      final attendanceResponse = await _supabase
          .from('user_class_attendance')
          .select('id, class_id, attended_at')
          .eq('user_id', user.id);

      final attendance = List<Map<String, dynamic>>.from(
          attendanceResponse as List? ?? []);

      if (attendance.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        return;
      }

      // Collect unique class IDs
      final classIds = attendance
          .map((r) => r['class_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      // Fetch class metadata for those IDs
    final classesResponse = await _supabase
      .from('classes')
      .select('id, class_name, difficulty, type_of_class, target_sessions')
      .filter('id', 'in', '(${classIds.join(',')})');

      final classes = List<Map<String, dynamic>>.from(
          classesResponse as List? ?? []);

      // Build a map of classId -> class data
      final Map<dynamic, Map<String, dynamic>> classMap = {
        for (final c in classes) c['id']: c,
      };

      // Count attendances per class
      final Map<dynamic, int> counts = {}; // class_id -> count
      for (final row in attendance) {
        final cid = row['class_id'];
        if (cid == null) continue;
        counts[cid] = (counts[cid] ?? 0) + 1;
      }

      // Build ClassProgress list
      final List<ClassProgress> items = [];
      for (final cid in classIds) {
        final cls = classMap[cid];
        final className = cls != null
            ? (cls['class_name']?.toString() ?? 'Unnamed class')
            : 'Class $cid';

        // Determine target sessions (how many sessions count as 'complete')
        // Use explicit `target_sessions` if present; otherwise derive from difficulty.
        int targetSessions = 10; // default fallback
        if (cls != null) {
          final ts = cls['target_sessions'];
          if (ts != null) {
            try {
              targetSessions = (ts as num).toInt();
            } catch (_) {
              targetSessions = int.tryParse(ts.toString()) ?? targetSessions;
            }
          } else {
            final diff = cls['difficulty'];
            int difficulty = 0;
            if (diff != null) {
              try {
                difficulty = (diff as num).toInt();
              } catch (_) {
                difficulty = int.tryParse(diff.toString()) ?? 0;
              }
            }
            // Heuristic: base 8 sessions + 4* difficulty
            targetSessions = 8 + (difficulty * 4);
            if (targetSessions <= 0) targetSessions = 8;
          }
        }

        final attended = counts[cid] ?? 0;
        final progress = targetSessions > 0
            ? (attended / targetSessions).clamp(0.0, 1.0)
            : 0.0;

        items.add(ClassProgress(
          classId: cid,
          className: className,
          attendedCount: attended,
          targetSessions: targetSessions,
          progressPercent: progress,
        ));
      }

      // Optionally sort by progress ascending (you can change this)
      items.sort((a, b) => a.className.compareTo(b.className));

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load progress: $e';
        _loading = false;
      });
    }
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
                                  return Card(
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
                                        ],
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

  ClassProgress({
    required this.classId,
    required this.className,
    required this.attendedCount,
    required this.targetSessions,
    required this.progressPercent,
  });
}