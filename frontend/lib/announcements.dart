import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'components/announcement_card.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  /// Load all announcements from Supabase
  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Fetch announcements ordered by created_at (newest first)
      final response = await _supabase
          .from('announcements')
          .select('*')
          .order('created_at', ascending: false);

      final announcements = List<Map<String, dynamic>>.from(response as List? ?? []);

      // Fetch author names for each announcement
      final List<Map<String, dynamic>> announcementsWithAuthors = [];

      for (final announcement in announcements) {
        final createdBy = announcement['created_by'] as String?;
        String authorName = 'Unknown';

        if (createdBy != null) {
          try {
            final profileResponse = await _supabase
                .from('profiles')
                .select('username, full_name')
                .eq('id', createdBy)
                .maybeSingle();

            if (profileResponse != null) {
              // Prefer full_name, fallback to username
              authorName = (profileResponse['full_name'] as String?)?.trim() ??
                  (profileResponse['username'] as String?)?.trim() ??
                  'Unknown';
            }
          } catch (e) {
            print('Error fetching author for announcement ${announcement['id']}: $e');
          }
        }

        announcementsWithAuthors.add({
          ...announcement,
          'author_name': authorName,
        });
      }

      if (mounted) {
        setState(() {
          _announcements = announcementsWithAuthors;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load announcements: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Parse DateTime from Supabase timestamptz
  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        print('Error parsing date: $dateTime, error: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.spaceLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppConstants.icon2xl,
                          color: AppConstants.errorColor,
                        ),
                        const SizedBox(height: AppConstants.spaceMd),
                        Text(
                          _errorMessage ?? 'An error occurred',
                          style: AppConstants.bodyMd.copyWith(
                            color: AppConstants.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.spaceLg),
                        ElevatedButton.icon(
                          onPressed: _loadAnnouncements,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: AppConstants.textOnPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _announcements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.campaign_outlined,
                            size: AppConstants.icon2xl,
                            color: AppConstants.textTertiary,
                          ),
                          const SizedBox(height: AppConstants.spaceMd),
                          Text(
                            'No announcements yet',
                            style: AppConstants.headingSm.copyWith(
                              color: AppConstants.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spaceXs),
                          Text(
                            'Check back later for updates',
                            style: AppConstants.bodySm.copyWith(
                              color: AppConstants.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAnnouncements,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spaceLg),
                        itemCount: _announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = _announcements[index];
                          final title = announcement['title']?.toString() ?? 'Untitled';
                          final body = announcement['body']?.toString() ?? '';
                          final authorName = announcement['author_name']?.toString() ?? 'Unknown';
                          final createdAt = _parseDateTime(announcement['created_at']);

                          return AnnouncementCard(
                            title: title,
                            body: body,
                            authorName: authorName,
                            createdAt: createdAt ?? DateTime.now(),
                          );
                        },
                      ),
                    );
  }
}
