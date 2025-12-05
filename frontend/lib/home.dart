import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/components/classes_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'announcements.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';
import 'track_progress_page.dart';
import 'qr_check_in_page.dart';

// Colors to be used in home page
class AppColors {
  static const primaryBlue = Color(0xFFDD886C);
  static const linkBlue = Color(0xFFC96E6E);
  static const fieldFill = Color(0xFFF1F3F6);
  static const background = Color(0xFFFFFDE2);
  static const primaryPeach = Color.fromARGB(255, 240, 172, 150);
  static const lightPink = Color.fromARGB(255, 255, 163, 238);
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

  String _getPageTitle() {
      switch (_selectedIndex) {
        case 0:
          return 'Martial Arts Hub';
        case 1:
          return 'Announcements';
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
             Text(
            'Quick Stats',
            style: AppConstants.headingLg.copyWith(
              color: AppConstants.textPrimary,
            ),
          ),
            _buildQuickStats(),
            
            SizedBox(height: AppConstants.spaceXl),
            
            // Track Progress Button
            _buildTrackProgressButton(context),
            
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
        color: AppConstants.backgroundColor,
      ),
      child: Column(
        children: [
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

  Widget _buildTrackProgressButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 320,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackingProgressPage(),
              ),
            );
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
          'Your Upcoming Classes',
          style: AppConstants.headingLg.copyWith(
            color: AppConstants.textPrimary,
          ),
        ),
        SizedBox(height: AppConstants.spaceLg),
        // Classes List
        _buildClassesList(),
      ],
    );
  }

  Widget _buildClassesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getRegisteredClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(AppConstants.spaceLg),
            child: Text(
              'Error loading classes',
              style: AppConstants.bodyMd.copyWith(color: AppConstants.textSecondary),
            ),
          );
        } else {
          final classes = snapshot.data ?? [];
          return ClassesList(
            classes: classes,
            onRegister: (classItem) {
            },
            onUnregister: (classItem) {
            },
            onEdit: (classItem) {
            },
            enableActions: false,
            classListType: ClassListType.card,
            onTap: (classItem) {
              // Handle class item tap
            },
          );
        }
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getRegisteredClasses() async {
    // Fetch registered classes for the user from the supabase
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      print("User not logged in");
      return [];
    }
    // Request the nested `classes` row to include schedule/coach fields when available
    final response = await Supabase.instance.client.from('student_classes').select('*, classes(id, class_name, date, time, coach_assigned, type_of_class, difficulty, goals_achieved)').eq('profile_id', userId);

    final classes = List<Map<String, dynamic>>.from(response as List? ?? []);
    // filter to show only classes in the next week
    classes.retainWhere((classItem) {
      final classData = classItem['classes'];
      if (classData == null) return false;
      final classDateStr = classData['date'] as String?;
      final classTimeStr = classData['time'] as String?;
      if (classDateStr == null) return false;
      if (classTimeStr == null) return false;
      // Combine date and time into a single DateTime object      
      final classDate = DateTime.parse(classDateStr);
      final classTime = TimeOfDay.fromDateTime(classDate);
      final classDateTime = DateTime(
        classDate.year,
        classDate.month,
        classDate.day,
        classTime.hour,
        classTime.minute,
      );
      // Check if classDateTime is within the next week
      final now = DateTime.now();
      final oneWeekFromNow = now.add(Duration(days: 7));
      print("Loaded classes after filtering: ${classes.length}");
      return classDateTime.isAfter(now) && classDateTime.isBefore(oneWeekFromNow);
    });
    // Add `import 'dart:convert';` at the top of the file
    final pretty = const JsonEncoder.withIndent('  ').convert(classes);
    debugPrint(pretty);
    return classes;
  }
}
