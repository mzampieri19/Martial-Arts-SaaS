import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:frontend/create_classes.dart';
import 'package:frontend/coach_bar_chart.dart';
import 'package:frontend/coach_bar_chart_class_count.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart';
import 'announcements.dart';
import 'calendar.dart';
import 'constants/app_constants.dart';
import 'components/index.dart';
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
          return 'Coach Hub';
        case 1:
          return 'Announcements';
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
            Text('Students Overview', style: AppConstants.headingMd.copyWith(color: AppConstants.textPrimary)),
            const StudentsOverview(),
            SizedBox(height: AppConstants.spaceMd),
            _buildCreateClassSection(context),
            SizedBox(height: AppConstants.spaceMd),
            _buildAnalyticsSection2_0(),
            SizedBox(height: AppConstants.spaceMd),
            _buildAnalyticsSection(),
            SizedBox(height: AppConstants.spaceMd),
            _buildDashboardSection(),
          ],
        ),
      ),
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

  // return: {#all classes, #finished classes, #unfinished classes}
  Future<List<int>> fetchRegisteredClasses() async {
    var res = List.filled(3, 0);
    var currentTimestamp = DateTime.now();
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    final profile = await supabase.from('profiles').select('username').eq('id', userId).maybeSingle();

    final username = profile?['username'] as String?;
    if (username==null) return [0, 0, 0];

    final allClasses = await supabase.from('classes').select('class_name').textSearch('coach_assigned', username);
    print(allClasses);
    final finishedClasses = await supabase.from('classes')
    .select('class_name').textSearch('coach_assigned', username).lt("date", currentTimestamp.toIso8601String());
    print(finishedClasses);
    print(allClasses.length - finishedClasses.length);
    res[0] = (allClasses as List).length; 
    res[1] = (finishedClasses as List).length; 
    res[2] = allClasses.length-finishedClasses.length;
    return res;
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Attendance Analytics',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: FutureBuilder(
            future: fetchAttendanceRate(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Could not load analytics: ${snapshot.error}');
              }
              return BarChartCoach();
            }
          )
        )
      ],
    );
  }

  Widget _buildAnalyticsSection2_0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Creation Analytics',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: FutureBuilder(
            future: fetchAttendanceRate(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Could not load analytics: ${snapshot.error}');
              }
              return BarChartCoachCount();
            }
          )
        )
      ],
    );
  }

  Widget _buildDashboardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class Progress',
          style: AppConstants.headingMd,
        ),
        SizedBox(height: AppConstants.spaceMd),
        // Placeholder for dashboard content
        Container(
          height: 200,
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppConstants.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: FutureBuilder(
            future: fetchRegisteredClasses(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text('Could not load classes: ${snapshot.error}');
              }

              final res = snapshot.data;
              int finishedClasses = res![1];
              int unfinishedClasses = res[0]-res[1];

              List<PieChartSectionData> pieChartSectionData = [
                PieChartSectionData(
                    value: finishedClasses.toDouble(),
                    title: 'Finished\nClasses',
                    titleStyle: TextStyle(
                      fontSize: 12, // Adjust this value to make the text smaller
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    titlePositionPercentageOffset: 1.8,
                    color: Color(0xffed733f),
                  ),
                  PieChartSectionData(
                    value: unfinishedClasses.toDouble(),
                    title: 'Upcoming\nClassses',
                    titleStyle: TextStyle(
                      fontSize: 12, // Adjust this value to make the text smaller
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    titlePositionPercentageOffset: 1.8,
                    color: Color(0xffd86f9b),
                  ),
              ];

              return PieChart(
                PieChartData(
                  sections: pieChartSectionData,
                )
              );
            }
          ),
        ),
      ],
    );
  }
}
