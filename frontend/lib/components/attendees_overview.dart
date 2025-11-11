// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../constants/app_constants.dart';
//   }
// }

//   @override
//   State<AttendeesOverview> createState() => _AttendeesOverviewState();
// }

// class _AttendeesOverviewState extends State<AttendeesOverview> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _students = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadStudentsOverview();
//   }

//   Future<void> _loadStudentsOverview() async {
//     setState(() => _loading = true);
//     final supabase = Supabase.instance.client;

//     try {
//       // fetch all student profiles
//       final profilesResp = await supabase.from('profiles').select('id, username, avatar_url, full_name, Role');
//       final profiles = List<Map<String, dynamic>>.from(profilesResp as List? ?? []);

//       final List<Map<String, dynamic>> studentsData = [];

//       for (final p in profiles) {
//         final role = (p['Role'] as String?)?.toLowerCase() ?? '';
//         if (role != 'student') continue;

//         final userId = p['id'] as String?;
//         if (userId == null) continue;

//         // registered classes
//         final regs = await supabase.from('student_classes').select('id').eq('user_id', userId);
//         final registeredCount = (regs as List?)?.length ?? 0;

//         // goals completed
//         final comps = await supabase.from('user_goal_completions').select('id, progress').eq('user_id', userId);
//         final compList = List<Map<String, dynamic>>.from(comps as List? ?? []);
//         final goalsCompleted = compList.where((c) {
//           final p = c['progress'];
//           if (p is int) return p > 0;
//           if (p is String) return int.tryParse(p) != null && int.parse(p) > 0;
//           return false;
//         }).length;
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../constants/app_constants.dart';

// class AttendeesOverview extends StatefulWidget {
//   const AttendeesOverview({super.key});

//   @override
//   State<AttendeesOverview> createState() => _AttendeesOverviewState();
// }

// class _AttendeesOverviewState extends State<AttendeesOverview> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _students = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadStudentsOverview();
//   }

//   Future<void> _loadStudentsOverview() async {
//     setState(() => _loading = true);
//     final supabase = Supabase.instance.client;

//     try {
//       // fetch all student profiles
//       final profilesResp = await supabase.from('profiles').select('id, username, avatar_url, full_name, Role');
//       final profiles = List<Map<String, dynamic>>.from(profilesResp as List? ?? []);

//       final List<Map<String, dynamic>> studentsData = [];

//       for (final p in profiles) {
//         final role = (p['Role'] as String?)?.toLowerCase() ?? '';
//         if (role != 'student') continue;

//         final userId = p['id'] as String?;
//         if (userId == null) continue;

//         // registered classes
//         final regs = await supabase.from('student_classes').select('id').eq('user_id', userId);
//         final registeredCount = (regs as List?)?.length ?? 0;

//         // goals completed
//         final comps = await supabase.from('user_goal_completions').select('id, progress').eq('user_id', userId);
//         final compList = List<Map<String, dynamic>>.from(comps as List? ?? []);
//         final goalsCompleted = compList.where((c) {
//           final p = c['progress'];
//           if (p is int) return p > 0;
//           if (p is String) return int.tryParse(p) != null && int.parse(p) > 0;
//           return false;
//         }).length;

//         // attendance counts (rpc returns list of {class_id, cnt})
//         int totalAttendance = 0;
//         try {
//           final attResp = await supabase.rpc('get_user_attendance_counts', params: {'p_user_id': userId});
//           final attList = List<Map<String, dynamic>>.from(attResp as List? ?? []);
//           for (final a in attList) {
//             final cnt = a['cnt'] ?? a['count'] ?? a['attendance_count'];
//             if (cnt is int) totalAttendance += cnt;
//             if (cnt is String) totalAttendance += int.tryParse(cnt) ?? 0;
//           }
//         } catch (_) {}

//         studentsData.add({
//           'id': userId,
//           'username': p['username'] ?? p['full_name'] ?? 'User',
//           'avatar_url': p['avatar_url'] as String?,
//           'registered': registeredCount,
//           'attendance': totalAttendance,
//           'goals_completed': goalsCompleted,
//         });
//       }

//       if (mounted) {
//         setState(() {
//           _students = studentsData;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() { _students = []; _loading = false; });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Center(child: CircularProgressIndicator());
//     if (_students.isEmpty) return const SizedBox.shrink();

//     return Container(
//       padding: EdgeInsets.all(AppConstants.spaceMd),
//       decoration: BoxDecoration(
//         color: AppConstants.surfaceColor,
//         borderRadius: BorderRadius.circular(AppConstants.radiusMd),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Students Overview', style: AppConstants.headingSm.copyWith(color: AppConstants.textPrimary)),
//           const SizedBox(height: 8),
//           ..._students.map((s) {
//             final avatar = s['avatar_url'] as String?;
//             final avatarUrl = (avatar != null && avatar.isNotEmpty)
//                 ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatar)
//                 : 'https://i.postimg.cc/cCsYDjvj/user-2.png';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../constants/app_constants.dart';

// class AttendeesOverview extends StatefulWidget {
//   const AttendeesOverview({super.key});

//   @override
//   State<AttendeesOverview> createState() => _AttendeesOverviewState();
// }

// class _AttendeesOverviewState extends State<AttendeesOverview> {
//   bool _loading = true;
//   List<Map<String, dynamic>> _students = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadStudentsOverview();
//   }

//   Future<void> _loadStudentsOverview() async {
//     setState(() => _loading = true);
//     final supabase = Supabase.instance.client;

//     try {
//       // fetch all student profiles
//       final profilesResp = await supabase.from('profiles').select('id, username, avatar_url, full_name, Role');
//       final profiles = List<Map<String, dynamic>>.from(profilesResp as List? ?? []);

//       final List<Map<String, dynamic>> studentsData = [];

//       for (final p in profiles) {
//         final role = (p['Role'] as String?)?.toLowerCase() ?? '';
//         if (role != 'student') continue;

//         final userId = p['id'] as String?;
//         if (userId == null) continue;

//         // registered classes
//         final regs = await supabase.from('student_classes').select('id').eq('user_id', userId);
//         final registeredCount = (regs as List?)?.length ?? 0;

//         // goals completed
//         final comps = await supabase.from('user_goal_completions').select('id, progress').eq('user_id', userId);
//         final compList = List<Map<String, dynamic>>.from(comps as List? ?? []);
//         final goalsCompleted = compList.where((c) {
//           final p = c['progress'];
//           if (p is int) return p > 0;
//           if (p is String) return int.tryParse(p) != null && int.parse(p) > 0;
//           return false;
//         }).length;

//         // attendance counts (rpc returns list of {class_id, cnt})
//         int totalAttendance = 0;
//         try {
//           final attResp = await supabase.rpc('get_user_attendance_counts', params: {'p_user_id': userId});
//           final attList = List<Map<String, dynamic>>.from(attResp as List? ?? []);
//           for (final a in attList) {
//             final cnt = a['cnt'] ?? a['count'] ?? a['attendance_count'];
//             if (cnt is int) totalAttendance += cnt;
//             if (cnt is String) totalAttendance += int.tryParse(cnt) ?? 0;
//           }
//         } catch (_) {}

//         studentsData.add({
//           'id': userId,
//           'username': p['username'] ?? p['full_name'] ?? 'User',
//           'avatar_url': p['avatar_url'] as String?,
//           'registered': registeredCount,
//           'attendance': totalAttendance,
//           'goals_completed': goalsCompleted,
//         });
//       }

//       if (mounted) {
//         setState(() {
//           _students = studentsData;
//           _loading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) setState(() { _students = []; _loading = false; });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Center(child: CircularProgressIndicator());
//     if (_students.isEmpty) return const SizedBox.shrink();

//     return Container(
//       padding: EdgeInsets.all(AppConstants.spaceMd),
//       decoration: BoxDecoration(
//         color: AppConstants.surfaceColor,
//         borderRadius: BorderRadius.circular(AppConstants.radiusMd),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Students Overview', style: AppConstants.headingSm.copyWith(color: AppConstants.textPrimary)),
//           const SizedBox(height: 8),
//           ..._students.map((s) {
//             final avatar = s['avatar_url'] as String?;
//             final avatarUrl = (avatar != null && avatar.isNotEmpty)
//                 ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatar)
//                 : 'https://i.postimg.cc/cCsYDjvj/user-2.png';

//             final username = s['username'] as String? ?? 'User';
//             final reg = s['registered'] as int? ?? 0;
//             final att = s['attendance'] as int? ?? 0;
//             final goals = s['goals_completed'] as int? ?? 0;

//             // simple progress metric (goals completed normalized by registered classes)
//             final double progressScore = ((goals.toDouble()) / (reg == 0 ? 1.0 : reg.toDouble())).clamp(0.0, 1.0).toDouble();

//             return Padding(
//               padding: const EdgeInsets.only(bottom: 12.0),
//               child: Row(
//                 children: [
//                   CircleAvatar(radius: 22, backgroundImage: NetworkImage(avatarUrl)),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(username, style: AppConstants.bodyMd.copyWith(color: AppConstants.textPrimary)),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Text('$reg classes', style: AppConstants.bodySm.copyWith(color: AppConstants.textSecondary)),
//                             const SizedBox(width: 12),
//                             Text('$att attendances', style: AppConstants.bodySm.copyWith(color: AppConstants.textSecondary)),
//                             const SizedBox(width: 12),
//                             Text('$goals goals', style: AppConstants.bodySm.copyWith(color: AppConstants.textSecondary)),
//                           ],
//                         ),
//                         const SizedBox(height: 6),
//                         ClipRRect(
//                           borderRadius: BorderRadius.circular(6),
//                           child: LinearProgressIndicator(
//                             value: progressScore,
//                             minHeight: 8,
//                             backgroundColor: AppConstants.primaryColor.withOpacity(0.12),
//                             valueColor: AlwaysStoppedAnimation(AppConstants.primaryColor),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ],
//       ),
//     );
//   }
// }
//               }
