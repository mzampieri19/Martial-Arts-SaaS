import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// General purpose app bar widget
/// Provides a customizable app bar with title, actions, and leading widget.
/// Can be used throughout the app for consistent app bar design.

class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title != null
          ? Text(
              title!,
              style: AppConstants.headingXs.copyWith(
                color: foregroundColor ?? AppConstants.textPrimary,
              ),
            )
          : null,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primaryBlue,
      foregroundColor: foregroundColor ?? AppConstants.textPrimary,
      elevation: elevation ?? 0,
      shadowColor: AppConstants.primaryColor.withOpacity(0.1),
      leading: leading ??
          (showBackButton && Navigator.of(context).canPop()
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios,
                    size: AppConstants.iconMd,
                  ),
                  onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      actions: actions,
      systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App bar with profile avatar and notifications
/// Used on the home screen to display user profile and notifications.

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? userProfile;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final int notificationCount;
  final Color backgroundColor;

  const HomeAppBar({
    super.key,
    this.userProfile,
    this.onProfileTap,
    this.onNotificationTap,
    this.notificationCount = 0, 
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBarWidget(
      title: 'Martial Arts Hub',
      centerTitle: false,
      showBackButton: false,
      actions: [
        // Notification icon with badge
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                size: AppConstants.iconLg,
              ),
              onPressed: onNotificationTap,
            ),
            if (notificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(AppConstants.spaceXs),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  constraints: BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    notificationCount > 99 ? '99+' : notificationCount.toString(),
                    style: AppConstants.labelXs.copyWith(
                      color: backgroundColor,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        
        // Profile avatar
        Padding(
          padding: EdgeInsets.only(right: AppConstants.spaceMd),
          child: GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryBlue,
              backgroundImage: userProfile != null ? NetworkImage(userProfile!) : null,
              child: userProfile == null
                  ? Icon(
                      Icons.person,
                      color: AppConstants.cardColor,
                      size: AppConstants.iconMd,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}