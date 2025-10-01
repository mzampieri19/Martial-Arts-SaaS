import 'package:flutter/material.dart';
import 'profile.dart';
import 'classes.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';

// Colors to be used in home page
class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
}

// Home page is just the bar and the bottom navigation, the actual content is in HomeContentPage
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeContentPage(), // Home content
    const ClassesPage(),
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
          return 'Martial Arts Hub';
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
class HomeContentPage extends StatelessWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppConstants.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Section
            _buildQuickStats(),
            
            SizedBox(height: AppConstants.spaceXl),
            
            // Track Progress Button
            _buildTrackProgressButton(),
            
            SizedBox(height: AppConstants.spaceXl),
            
            // Dashboard Section
            _buildDashboardSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(AppConstants.spaceLg),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: AppConstants.headingSm.copyWith(
              color: AppConstants.textPrimary,
            ),
          ),
          SizedBox(height: AppConstants.spaceMd),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Classes This Week',
                  value: '5',
                  icon: Icons.sports_martial_arts_rounded,
                  color: AppConstants.accentColor,
                ),
              ),
              SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: _buildStatCard(
                  title: 'Training Hours',
                  value: '12.5',
                  icon: Icons.timer_rounded,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceMd),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Current Belt',
                  value: 'Blue',
                  icon: Icons.military_tech_rounded,
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: _buildStatCard(
                  title: 'Next Class',
                  value: 'Today 6PM',
                  icon: Icons.schedule_rounded,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: AppConstants.iconLg,
          ),
          SizedBox(height: AppConstants.spaceSm),
          Text(
            value,
            style: AppConstants.headingMd.copyWith(
              color: AppConstants.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppConstants.labelSm.copyWith(
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackProgressButton() {
    return Center(
      child: SizedBox(
        width: 320,
        child: ElevatedButton(
          onPressed: () {
            // Navigate to track progress page
          },
          child: const Text('Track Progress'),
        ),
      ),
    );
  }

  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: AppConstants.headingLg.copyWith(
            color: AppConstants.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spaceLg),
        
        // Filter Section
        _buildFilters(),
        
        SizedBox(height: AppConstants.spaceLg),
        
        // Classes List
        _buildClassesList(),
      ],
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Classes', true),
          SizedBox(width: AppConstants.spaceSm),
          _buildFilterChip('Karate', false),
          SizedBox(width: AppConstants.spaceSm),
          _buildFilterChip('BJJ', false),
          SizedBox(width: AppConstants.spaceSm),
          _buildFilterChip('Muay Thai', false),
          SizedBox(width: AppConstants.spaceSm),
          _buildFilterChip('This Week', false),
          SizedBox(width: AppConstants.spaceSm),
          _buildFilterChip('Today', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spaceMd,
        vertical: AppConstants.spaceSm,
      ),
      decoration: BoxDecoration(
        color: isSelected 
            ? AppConstants.accentColor 
            : AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(
          color: isSelected 
              ? AppConstants.accentColor 
              : AppConstants.grey300,
        ),
      ),
      child: Text(
        label,
        style: AppConstants.labelSm.copyWith(
          color: isSelected 
              ? Colors.white 
              : AppConstants.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    final classes = [
      {
        'name': 'Karate Fundamentals',
        'instructor': 'Sensei Johnson',
        'time': 'Today, 6:00 PM - 7:30 PM',
        'type': 'Karate',
        'difficulty': 'Beginner',
        'color': Colors.orange,
      },
      {
        'name': 'BJJ Advanced Techniques',
        'instructor': 'Professor Silva',
        'time': 'Tomorrow, 7:00 PM - 8:30 PM',
        'type': 'BJJ',
        'difficulty': 'Advanced',
        'color': Colors.blue,
      },
      {
        'name': 'Muay Thai Conditioning',
        'instructor': 'Kru Martinez',
        'time': 'Wednesday, 6:30 PM - 8:00 PM',
        'type': 'Muay Thai',
        'difficulty': 'Intermediate',
        'color': Colors.red,
      },
      {
        'name': 'Open Mat Session',
        'instructor': 'Various',
        'time': 'Friday, 7:00 PM - 9:00 PM',
        'type': 'Open Mat',
        'difficulty': 'All Levels',
        'color': Colors.green,
      },
      {
        'name': 'Self Defense Workshop',
        'instructor': 'Instructor Lee',
        'time': 'Saturday, 10:00 AM - 12:00 PM',
        'type': 'Self Defense',
        'difficulty': 'Beginner',
        'color': Colors.purple,
      },
    ];

    return Column(
      children: classes.map((classData) => _buildClassCard(classData)).toList(),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.spaceMd),
      padding: EdgeInsets.all(AppConstants.spaceLg),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: classData['color'],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      classData['name'],
                      style: AppConstants.headingSm.copyWith(
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    Text(
                      'with ${classData['instructor']}',
                      style: AppConstants.bodyMd.copyWith(
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceSm,
                  vertical: AppConstants.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: classData['color'].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Text(
                  classData['difficulty'],
                  style: AppConstants.labelXs.copyWith(
                    color: classData['color'],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceMd),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: AppConstants.iconSm,
                color: AppConstants.textSecondary,
              ),
              SizedBox(width: AppConstants.spaceXs),
              Text(
                classData['time'],
                style: AppConstants.bodyMd.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppConstants.spaceSm),
          Row(
            children: [
              Icon(
                Icons.sports_martial_arts_rounded,
                size: AppConstants.iconSm,
                color: AppConstants.textSecondary,
              ),
              SizedBox(width: AppConstants.spaceXs),
              Text(
                classData['type'],
                style: AppConstants.bodyMd.copyWith(
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
