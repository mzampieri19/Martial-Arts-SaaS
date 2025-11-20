import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Widget to display a single announcement card
class AnnouncementCard extends StatelessWidget {
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });

  /// Format the date for display
  String get _formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format: "Jan 15, 2024"
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months[createdAt.month - 1];
      return '$month ${createdAt.day}, ${createdAt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      elevation: AppConstants.elevationSm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title and Date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppConstants.headingSm.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Text(
                  _formattedDate,
                  style: AppConstants.bodyXs.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spaceMd),
            
            // Body
            Text(
              body,
              style: AppConstants.bodyMd.copyWith(
                color: AppConstants.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),
            
            // Footer: Author
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: AppConstants.iconSm,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: AppConstants.spaceXs),
                Text(
                  authorName,
                  style: AppConstants.bodyXs.copyWith(
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

