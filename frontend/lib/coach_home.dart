import 'package:flutter/material.dart';
import 'package:frontend/create_classes.dart';
import 'profile.dart';
import 'announcements.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';
import 'qr_check_in_page.dart';

// Colors to be used in home page
class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

// Home page is just the bar and the bottom navigation, the actual content is in HomeContentPage
class CoachHomePage extends StatefulWidget {
  const CoachHomePage({super.key});

  @override
  State<CoachHomePage> createState() => _CoachHomePageState();
}

class _CoachHomePageState extends State<CoachHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CoachHomeContentPage(), // Home content
    const AnnouncementsPage(),
    const CalendarPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToNotifications() {
    // Navigate to notifications
  }

  String _getPageTitle() {
      switch (_selectedIndex) {
        case 0:
          return 'Coach Hub';
        case 1:
          return 'Make Classes';
        case 2:
          return 'Calendar';
        case 3:
          return 'Coach Profile';
        default:
          return 'Martial Arts Hub';
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _selectedIndex == 0 
          ? HomeAppBar(
              onProfileTap: () => _onItemTapped(3),
              onNotificationTap: _navigateToNotifications,
              notificationCount: 3, // Hard coded for now
              backgroundColor: AppColors.primaryBlue,
            )
          : AppBarWidget(
              title: _getPageTitle(),
              showBackButton: false,
            ),
      body: Stack(
        children: [
          // Main content with padding at bottom for floating nav
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: 95), // Space for floating nav with notch
              child: _pages[_selectedIndex],
            ),
          ),
          // Floating bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MartialArtsBottomNavigation(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              onCenterButtonTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRCheckInPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick action button for the center button modal
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(AppConstants.spaceMd),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppConstants.accentColor,
              size: AppConstants.iconXl,
            ),
          ),
          SizedBox(height: AppConstants.spaceSm),
          Text(
            label,
            style: AppConstants.labelSm,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Home content page widget
class CoachHomeContentPage extends StatelessWidget {
  const CoachHomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, Coach!',
              style: AppConstants.headingLg,
            ),
            SizedBox(height: AppConstants.spaceMd),
            _buildOverviewSection(),
            SizedBox(height: AppConstants.spaceXl),
            _buildCreateClassSection(context),
            SizedBox(height: AppConstants.spaceXl),
            _buildDashboardSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        // Placeholder for overview content
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Center(
            child: Text(
              'Overview Content Here',
              style: AppConstants.bodyMd.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateClassSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a New Class',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateClassesPage(),
              ),
            );
          },
          child: Text('Make a Class'),
        ),
      ],
    );
  }

  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        // Placeholder for dashboard content
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Center(
            child: Text(
              'Dashboard Content Here',
              style: AppConstants.bodyMd.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
