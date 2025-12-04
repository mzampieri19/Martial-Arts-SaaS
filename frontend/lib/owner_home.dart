import 'package:flutter/material.dart';
import 'package:frontend/create_classes.dart';
import 'package:frontend/edit_class.dart';
import 'profile_page.dart';
import 'announcements.dart';
import 'create_announcement.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';
import 'components/students_overview.dart';
import 'qr_check_in_page.dart';
import 'view_class_qr_codes_page.dart';

// Colors to be used in home page
class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

// Home page is just the bar and the bottom navigation, the actual content is in HomeContentPage
class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const OwnerHomeContentPage(), // Home content
    const AnnouncementsPage(),
    const CalendarPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToNotifications() {
    // Navigate to notifications
  }

  /// Show quick action menu for coaches/owners
  void _showQuickActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan QR Code',
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QRCheckInPage(),
                      ),
                    );
                  },
                ),
                _QuickActionButton(
                  icon: Icons.qr_code_2_rounded,
                  label: 'View Class QR Codes',
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ViewClassQRCodesPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getPageTitle() {
      switch (_selectedIndex) {
        case 0:
          return 'Owner Hub';
        case 1:
          return 'Announcements';
        case 2:
          return 'Calendar';
        case 3:
          return 'Owner Profile';
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
              onCenterButtonTap: () => _showQuickActionMenu(context),
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
class OwnerHomeContentPage extends StatelessWidget {
  const OwnerHomeContentPage({super.key});

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
              'Welcome back, Owner!',
              style: AppConstants.headingLg,
            ),
            SizedBox(height: AppConstants.spaceMd),
            Text('Students Overview', style: AppConstants.headingMd.copyWith(color: AppConstants.textPrimary)),
            const StudentsOverview(),
            SizedBox(height: AppConstants.spaceMd),
            _buildCreateClassSection(context),
            SizedBox(height: AppConstants.spaceMd),
            _buildCreateAnnouncementSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAnnouncementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Announcement Management',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateAnnouncementPage(),
              ),
            );
          },
          child: const Text('Create Announcement'),
        ),
      ],
    );
  }

  Widget _buildCreateClassSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Management',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateClassesPage(),
                    ),
                  );
                },
                child: const Text('Make a Class'),
              ),
            ),
            SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditClassPage(),
                    ),
                  );
                },
                child: const Text('Edit an Existing Class'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
