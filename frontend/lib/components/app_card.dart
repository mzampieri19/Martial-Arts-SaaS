import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_button.dart';

/// Card variants for the app card
enum AppCardVariant { elevated, outlined, filled }

/// Card sizes for the app card
enum AppCardSize { small, medium, large }

/// Customizable card widget with various sizes and variants
class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final AppCardSize size;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsets? margin;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.size = AppCardSize.medium,
    this.onTap,
    this.backgroundColor,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Material(
        color: backgroundColor ?? _getBackgroundColor(),
        elevation: _getElevation(),
        shadowColor: AppConstants.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          side: _getBorderSide(),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          child: Padding(
            padding: _getPadding(),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppCardVariant.elevated:
        return AppConstants.accentColorDark;
      case AppCardVariant.outlined:
        return AppConstants.accentColorDark;
      case AppCardVariant.filled:
        return AppConstants.accentColorDark;
    }
  }

  double _getElevation() {
    switch (variant) {
      case AppCardVariant.elevated:
        return AppConstants.elevationMd;
      case AppCardVariant.outlined:
        return 0;
      case AppCardVariant.filled:
        return 0;
    }
  }

  BorderSide _getBorderSide() {
    switch (variant) {
      case AppCardVariant.elevated:
        return BorderSide.none;
      case AppCardVariant.outlined:
        return BorderSide(
          color: AppConstants.grey200,
          width: 1,
        );
      case AppCardVariant.filled:
        return BorderSide.none;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppCardSize.small:
        return EdgeInsets.all(AppConstants.spaceMd);
      case AppCardSize.medium:
        return EdgeInsets.all(AppConstants.spaceLg);
      case AppCardSize.large:
        return EdgeInsets.all(AppConstants.spaceXl);
    }
  }
}

/// Specialized card for class listings
class ClassCard extends StatelessWidget {
  final String title;
  final String instructor;
  final String time;
  final String duration;
  final String difficulty;
  final int spotsAvailable;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onBookTap;

  const ClassCard({
    super.key,
    required this.title,
    required this.instructor,
    required this.time,
    required this.duration,
    required this.difficulty,
    required this.spotsAvailable,
    this.imageUrl,
    this.onTap,
    this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image or placeholder (This will be replaced with actual image logic)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              color: AppConstants.grey100,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl == null
              ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                  Icons.sports_martial_arts,
                  size: AppConstants.icon2xl,
                  color: AppConstants.textTertiary,
                  ),
                  SizedBox(height: AppConstants.spaceXs),
                  Text(
                  'Image will be added later',
                  style: AppConstants.bodyXs.copyWith(
                    color: AppConstants.textTertiary,
                  ),
                  ),
                ],
                )
              : null,
            ),
            SizedBox(height: AppConstants.spaceMd),
          
          // Class title
          Text(
            title,
            style: AppConstants.headingSm,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppConstants.spaceXs),
          
          // Instructor
          Text(
            'with $instructor',
            style: AppConstants.bodySm.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
          SizedBox(height: AppConstants.spaceMd),
          
          // Time and duration
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: AppConstants.iconSm,
                color: AppConstants.textSecondary,
              ),
              SizedBox(width: AppConstants.spaceXs),
              Text(
                '$time • $duration',
                style: AppConstants.bodySm.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceXs),
          
          // Difficulty and spots
          Row(
            children: [
              Spacer(),
              Text(
                '$spotsAvailable spots left',
                style: AppConstants.bodyXs.copyWith(
                  color: spotsAvailable > 5 
                      ? AppConstants.successColor 
                      : AppConstants.warningColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceMd),
          
          // Book button
          if (onBookTap != null)
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: spotsAvailable > 0 ? 'Book Class' : 'Join Waitlist',
                onPressed: spotsAvailable > 0 ? onBookTap : null,
                size: AppButtonSize.small,
                variant: spotsAvailable > 0 
                    ? AppButtonVariant.primary 
                    : AppButtonVariant.outline,
              ),
            ),
        ],
      ),
    );
  }
}