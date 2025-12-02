import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

// Widget to display an overview of students with their stats

class StudentsOverview extends StatefulWidget {
  const StudentsOverview({super.key});

  @override
  State<StudentsOverview> createState() => _StudentsOverviewState();
}

class _StudentsOverviewState extends State<StudentsOverview> {
  bool _loading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudentsOverview();
  }

  // Load students and their stats from Supabase
  Future<void> _loadStudentsOverview() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;

    try {
      // fetch all STUDENT profiles
      final profilesResp = await supabase.from('profiles').select('id, username, avatar_url, full_name, Role');
      final profiles = List<Map<String, dynamic>>.from(profilesResp as List? ?? []);

      final List<Map<String, dynamic>> studentsData = [];

      // fetch stats per student
      for (final p in profiles) {
        final role = (p['Role'] as String?)?.toLowerCase() ?? '';
        if (role != 'student') continue;

        final userId = p['id'] as String?;
        if (userId == null) continue;

        int registeredCount = 0;
        try {
          final regResp = await supabase
              .from('student_classes')
              .select('id')
              .eq('profile_id', userId.toString());
          final regList = regResp as List?;
          registeredCount = regList?.length ?? 0;
        } catch (e) {
          print('student_classes fetch failed for profile_id=$userId: $e');
          registeredCount = 0;
        }

        int goalsCompleted = 0;
        int totalAttendance = 0;

        // fetch goals completed count
        try {
          final rpcGoals = await supabase.rpc('get_user_goals_completed_admin', params: {'p_user_id': userId.toString()});
          if (rpcGoals is int) {
            goalsCompleted = rpcGoals;
          } else if (rpcGoals is List && rpcGoals.isNotEmpty) {
            final first = rpcGoals.first;
            if (first is Map && first.values.isNotEmpty) {
              final val = first.values.first;
              if (val is int) goalsCompleted = val;
              if (val is String) goalsCompleted = int.tryParse(val) ?? 0;
            } else if (first is int) {
              goalsCompleted = first;
            }
          }
        } catch (_) {
          try {
            final comps = await supabase.from('user_goal_completions').select('id, progress').eq('user_id', userId.toString());
            final compList = List<Map<String, dynamic>>.from(comps as List? ?? []);
            goalsCompleted = compList.where((c) {
              final prog = c['progress'];
              if (prog is int) return prog > 0;
              if (prog is String) return int.tryParse(prog) != null && int.parse(prog) > 0;
              return false;
            }).length;
          } catch (e) {
            print('user_goal_completions fetch failed for user_id=$userId: $e');
            goalsCompleted = 0;
          }
        }
        // fetch attendance count
        try {
          final rpcAtt = await supabase.rpc('get_user_class_stats_admin', params: {'p_user_id': userId.toString()});
          final rpcList = rpcAtt as List?;
          if (rpcList != null && rpcList.isNotEmpty) {
            for (final r in rpcList) {
              if (r is Map) {
                final cnt = r['attended_count'] ?? r['attended'] ?? r['attended_count'];
                if (cnt is int) totalAttendance += cnt;
                if (cnt is String) totalAttendance += int.tryParse(cnt) ?? 0;
              }
            }
          } else {
            final attResp = await supabase.from('user_class_attendance').select('id').eq('user_id', userId.toString());
            final attList = attResp as List?;
            totalAttendance = attList?.length ?? 0;
          }
        } catch (_) {
          try {
            final attResp = await supabase.from('user_class_attendance').select('id').eq('user_id', userId.toString());
            final attList = attResp as List?;
            totalAttendance = attList?.length ?? 0;
          } catch (e) {
            print('user_class_attendance fetch failed for user_id=$userId: $e');
            totalAttendance = 0;
          }
        }
        // combine all data
        studentsData.add({
          'id': userId,
          'username': p['username'] ?? 'User',
          'full_name': p['full_name'] ?? 'User Name',
          'avatar_url': p['avatar_url'] as String?,
          'registered': registeredCount,
          'attendance': totalAttendance,
          'goals_completed': goalsCompleted,
        });
      }

      if (mounted) {
        setState(() {
          _students = studentsData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _students = []; _loading = false; });
    }
  }

  @override
  // Build the widget UI
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_students.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._students.map((s) {
            final avatar = s['avatar_url'] as String?;
            final avatarUrl = (avatar != null && avatar.isNotEmpty)
                ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatar)
                : 'https://i.postimg.cc/cCsYDjvj/user-2.png';

            final username = s['full_name'] as String? ?? 'User';
            final reg = s['registered'] as int? ?? 0;
            final att = s['attendance'] as int? ?? 0;
            final goals = s['goals_completed'] as int? ?? 0;

            // simple progress metric (goals completed normalized by registered classes)
            final double progressScore = ((goals.toDouble()) / (reg == 0 ? 1.0 : reg.toDouble())).clamp(0.0, 1.0).toDouble();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: AppConstants.bodyMd.copyWith(color: AppConstants.textPrimary)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$reg classes registered',
                                style: AppConstants.bodySm.copyWith(color: AppConstants.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '$att classes attended',
                                style: AppConstants.bodySm.copyWith(color: AppConstants.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '$goals goals mastered',
                                style: AppConstants.bodySm.copyWith(color: AppConstants.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressScore,
                            minHeight: 8,
                            backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
                            valueColor: AlwaysStoppedAnimation(AppConstants.accentColorDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}