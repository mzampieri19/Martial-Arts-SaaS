import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class AttendeesOverview extends StatefulWidget {
  const AttendeesOverview({super.key});

  @override
  State<AttendeesOverview> createState() => _AttendeesOverviewState();
}

class _AttendeesOverviewState extends State<AttendeesOverview> {
  bool _loading = true;
  Map<String, List<Map<String, dynamic>>> _grouped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _grouped = {};
        _loading = false;
      });
      return;
    }

    try {
      final profile = await supabase.from('profiles').select('username, Role').eq('id', user.id).maybeSingle();
      final role = (profile?['Role'] as String?)?.toLowerCase() ?? 'student';
      final username = profile?['username'] as String?;

      List<Map<String, dynamic>> classes = [];
      if (role == 'coach' && username != null) {
        final classesResp = await supabase.from('classes').select('id, class_name').eq('coach_assigned', username);
        classes = List<Map<String, dynamic>>.from(classesResp as List? ?? []);
      } else if (role == 'owner') {
        final classesResp = await supabase.from('classes').select('id, class_name');
        classes = List<Map<String, dynamic>>.from(classesResp as List? ?? []);
      } else {
        classes = [];
      }

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final c in classes) {
        final cid = c['id'];
        final cname = c['class_name'] ?? 'Unnamed Class';
        try {
          final regs = await supabase.from('student_classes').select('*, profiles(username, avatar_url)').eq('class_id', cid);
          final regsList = List<Map<String, dynamic>>.from(regs as List? ?? []);
          if (regsList.isNotEmpty) grouped[cname] = regsList;
        } catch (_) {}
      }

      if (mounted) setState(() {
        _grouped = grouped;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _grouped = {};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_grouped.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendees Overview', style: AppConstants.headingSm.copyWith(color: AppConstants.textPrimary)),
          const SizedBox(height: 8),
          ..._grouped.entries.map((entry) {
            final className = entry.key;
            final attendees = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4.0),
                title: Row(
                  children: [
                    Expanded(child: Text(className, style: AppConstants.labelLg.copyWith(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${attendees.length} registered', style: AppConstants.labelSm.copyWith(color: AppConstants.textSecondary)),
                    ),
                  ],
                ),
                children: attendees.map((a) {
                  final username = a['profiles']?['username'] ?? a['username'] ?? 'User';
                  final avatar = a['profiles']?['avatar_url'] as String?;
                  final avatarUrl = (avatar != null && avatar.isNotEmpty)
                      ? Supabase.instance.client.storage.from('avatars').getPublicUrl(avatar)
                      : 'https://i.postimg.cc/cCsYDjvj/user-2.png';
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(avatarUrl)),
                    title: Text(username, style: AppConstants.bodyMd.copyWith(color: AppConstants.textPrimary)),
                    subtitle: Text('Registered: ${a['created_at'] ?? ''}', style: AppConstants.bodySm.copyWith(color: AppConstants.textSecondary)),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
