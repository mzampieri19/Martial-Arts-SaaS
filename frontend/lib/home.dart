import 'package:flutter/material.dart';
import 'profile.dart';
import 'classes.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContentPage(),
    const ClassesPage(),
    const CalendarPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: _selectedIndex == 0 
          ? HomeAppBar(
              onProfileTap: () => _onItemTapped(3),
              onNotificationTap: () {
                // TODO: Navigate to notifications
              },
              notificationCount: 3,
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
                // Handle center button tap - could open quick actions
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Container(
                    margin: EdgeInsets.all(AppConstants.spaceLg),
                    padding: EdgeInsets.all(AppConstants.spaceLg),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(AppConstants.radiusXl),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quick Actions', //This can be removed as well and just be made into one icon
                          style: AppConstants.headingSm,
                        ),
                        SizedBox(height: AppConstants.spaceLg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _QuickActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Scan QR',
                              onTap: () => Navigator.pop(context),
                            ),
                             _QuickActionButton(
                              icon: Icons.qr_code_scanner,
                              label: 'Can Add More Later',
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Classes';
      case 2:
        return 'Calendar';
      case 3:
        return 'Profile';
      default:
        return 'Martial Arts Hub';
    }
  }
}

/// Home page content with sample martial arts classes
class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Text(
            'Welcome back!',
            style: AppConstants.headingLg,
          ),
          SizedBox(height: AppConstants.spaceXs),
          Text(
            'Ready for your next training session?',
            style: AppConstants.bodyMd.copyWith(
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spaceXl),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: AppCard(
                  size: AppCardSize.small,
                  child: Column(
                    children: [
                      Text(
                        '12', // Hardcoded for demo purposes
                        style: AppConstants.headingLg.copyWith(
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Text(
                        'Classes This Month',
                        style: AppConstants.bodySm.copyWith(
                          color: AppConstants.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: AppCard(
                  size: AppCardSize.small,
                  child: Column(
                    children: [
                      Text(
                        '5', // Hardcoded for demo purposes
                        style: AppConstants.headingLg.copyWith(
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      Text(
                        'Belt Levels', 
                        style: AppConstants.bodySm.copyWith(
                          color: AppConstants.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceXl),

          // Upcoming classes section
          Text(
            'Upcoming Classes',
            style: AppConstants.headingMd,
          ),
          SizedBox(height: AppConstants.spaceMd),

          // Sample class cards
          ClassCard(
            title: 'Karate Basics',
            instructor: 'Sensei Smith',
            time: '6:00 PM',
            duration: '1 hour',
            difficulty: 'Beginner',
            spotsAvailable: 8,
            onBookTap: () {
              // TODO: Handle booking
            },
          ),
          SizedBox(height: AppConstants.spaceMd),
          
          ClassCard(
            title: 'Advanced Taekwondo',
            instructor: 'Master Kim',
            time: '7:30 PM',
            duration: '1.5 hours',
            difficulty: 'Advanced',
            spotsAvailable: 3,
            onBookTap: () {
              // TODO: Handle booking
            },
          ),
          SizedBox(height: AppConstants.spaceMd),
          
          ClassCard(
            title: 'Brazilian Jiu-Jitsu',
            instructor: 'Professor Silva',
            time: '8:00 PM',
            duration: '2 hours',
            difficulty: 'Intermediate',
            spotsAvailable: 0,
            onBookTap: () {
              // TODO: Handle waitlist
            },
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
