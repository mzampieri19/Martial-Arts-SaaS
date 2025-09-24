import 'package:flutter/material.dart';
import 'dart:ui';
import '../constants/app_constants.dart';

/// Customizable bottom navigation bar with optional center floating button

class AppBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;
  final Widget? centerButton;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.centerButton,
  });

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation>
    with TickerProviderStateMixin {
  int? hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: AppConstants.spaceLg,
        right: AppConstants.spaceLg,
        bottom: AppConstants.spaceLg,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: NavBarPainter(),
            child: ClipPath(
              clipper: NavBarClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: _buildNavItems(),
                  ),
                ),
              ),
            ),
          ),
          // Center floating button
          if (widget.centerButton != null)
            Positioned(
              top: -15,
              left: MediaQuery.of(context).size.width / 2 - AppConstants.spaceLg - 30,
              child: widget.centerButton!,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems() {
    final itemCount = widget.items.length;
    final leftItems = widget.items.take(itemCount ~/ 2).toList();
    final rightItems = widget.items.skip(itemCount ~/ 2).toList();

    return [
      // Left side items
      ...leftItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildNavItem(item, index);
      }),
      // Center space for floating button
      const Expanded(child: SizedBox()),
      // Right side items
      ...rightItems.asMap().entries.map((entry) {
        final index = entry.key + leftItems.length;
        final item = entry.value;
        return _buildNavItem(item, index);
      }),
    ];
  }

  Widget _buildNavItem(AppBottomNavItem item, int index) {
    final isSelected = index == widget.currentIndex;
    final isHovered = index == hoveredIndex;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => hoveredIndex = index),
        onExit: (_) => setState(() => hoveredIndex = null),
        child: GestureDetector(
          onTap: () => widget.onTap(index),
          child: AnimatedContainer(
            duration: AppConstants.animationNormal,
            curve: Curves.easeInOut,
            margin: EdgeInsets.symmetric(
              horizontal: AppConstants.spaceXs,
              vertical: AppConstants.spaceSm,
            ),
            decoration: BoxDecoration(
              color: _getBackgroundColor(isSelected, isHovered),
              borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppConstants.animationNormal,
                  curve: Curves.easeInOut,
                  transform: Matrix4.identity()
                    ..scale(isSelected || isHovered ? 1.1 : 1.0),
                  child: Icon(
                    isSelected 
                      ? (item.activeIcon ?? item.icon)
                      : item.icon,
                    size: AppConstants.iconMd,
                    color: _getIconColor(isSelected, isHovered),
                  ),
                ),
                SizedBox(height: AppConstants.spaceXs),
                AnimatedDefaultTextStyle(
                  duration: AppConstants.animationNormal,
                  curve: Curves.easeInOut,
                  style: AppConstants.labelXs.copyWith(
                    color: _getTextColor(isSelected, isHovered),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 10,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }  Color _getBackgroundColor(bool isSelected, bool isHovered) {
    if (isSelected) {
      return AppConstants.primaryColor.withOpacity(0.15);
    } else if (isHovered) {
      return AppConstants.primaryColor.withOpacity(0.08);
    }
    return Colors.transparent;
  }

  Color _getIconColor(bool isSelected, bool isHovered) {
    if (isSelected) {
      return AppConstants.primaryColor;
    } else if (isHovered) {
      return AppConstants.primaryColor.withOpacity(0.8);
    }
    return AppConstants.textTertiary;
  }

  Color _getTextColor(bool isSelected, bool isHovered) {
    if (isSelected) {
      return AppConstants.primaryColor;
    } else if (isHovered) {
      return AppConstants.textPrimary;
    }
    return AppConstants.textTertiary;
  }
}

/// Custom painter for the navigation bar background with notch
/// Creates a smooth, rounded background for the navigation bar with a central notch.

class NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.surfaceColor.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Start from bottom left with rounded corner
    path.moveTo(AppConstants.radiusXl, size.height);
    path.lineTo(0, size.height - AppConstants.radiusXl);
    path.quadraticBezierTo(0, size.height, AppConstants.radiusXl, size.height);
    
    // Left side
    path.lineTo(size.width / 2 - 50, size.height);
    
    // Create notch for center button
    path.quadraticBezierTo(size.width / 2 - 35, size.height, size.width / 2 - 35, size.height - 15);
    path.quadraticBezierTo(size.width / 2 - 35, size.height - 30, size.width / 2 - 20, size.height - 35);
    path.lineTo(size.width / 2 + 20, size.height - 35);
    path.quadraticBezierTo(size.width / 2 + 35, size.height - 30, size.width / 2 + 35, size.height - 15);
    path.quadraticBezierTo(size.width / 2 + 35, size.height, size.width / 2 + 50, size.height);
    
    // Right side
    path.lineTo(size.width - AppConstants.radiusXl, size.height);
    
    // Bottom right corner
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - AppConstants.radiusXl);
    
    // Right edge
    path.lineTo(size.width, AppConstants.radiusXl);
    
    // Top right corner
    path.quadraticBezierTo(size.width, 0, size.width - AppConstants.radiusXl, 0);
    
    // Top edge
    path.lineTo(AppConstants.radiusXl, 0);
    
    // Top left corner
    path.quadraticBezierTo(0, 0, 0, AppConstants.radiusXl);
    
    // Left edge
    path.lineTo(0, size.height - AppConstants.radiusXl);
    
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    // Start from bottom left with rounded corner
    path.moveTo(AppConstants.radiusXl, size.height);
    path.lineTo(0, size.height - AppConstants.radiusXl);
    path.quadraticBezierTo(0, size.height, AppConstants.radiusXl, size.height);
    
    // Left side
    path.lineTo(size.width / 2 - 50, size.height);
    
    // Create notch for center button
    path.quadraticBezierTo(size.width / 2 - 35, size.height, size.width / 2 - 35, size.height - 15);
    path.quadraticBezierTo(size.width / 2 - 35, size.height - 30, size.width / 2 - 20, size.height - 35);
    path.lineTo(size.width / 2 + 20, size.height - 35);
    path.quadraticBezierTo(size.width / 2 + 35, size.height - 30, size.width / 2 + 35, size.height - 15);
    path.quadraticBezierTo(size.width / 2 + 35, size.height, size.width / 2 + 50, size.height);
    
    // Right side
    path.lineTo(size.width - AppConstants.radiusXl, size.height);
    
    // Bottom right corner
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - AppConstants.radiusXl);
    
    // Right edge
    path.lineTo(size.width, AppConstants.radiusXl);
    
    // Top right corner
    path.quadraticBezierTo(size.width, 0, size.width - AppConstants.radiusXl, 0);
    
    // Top edge
    path.lineTo(AppConstants.radiusXl, 0);
    
    // Top left corner
    path.quadraticBezierTo(0, 0, 0, AppConstants.radiusXl);
    
    // Left edge
    path.lineTo(0, size.height - AppConstants.radiusXl);
    
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AppBottomNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const AppBottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// Floating center button for navigation
class FloatingCenterButton extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;

  const FloatingCenterButton({
    super.key,
    this.onTap,
    this.icon = Icons.add,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<FloatingCenterButton> createState() => _FloatingCenterButtonState();
}

class _FloatingCenterButtonState extends State<FloatingCenterButton>
    with SingleTickerProviderStateMixin {
  bool isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationFast,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? AppConstants.secondaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.backgroundColor ?? AppConstants.secondaryColor)
                          .withOpacity(0.3),
                      blurRadius: isHovered ? 15 : 10,
                      offset: const Offset(0, 5),
                      spreadRadius: isHovered ? 2 : 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor ?? AppConstants.textOnPrimary,
                  size: 28,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Pre-configured floating bottom navigation for the martial arts app
class MartialArtsBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onCenterButtonTap;

  const MartialArtsBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onCenterButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBottomNavigation(
      currentIndex: currentIndex,
      onTap: onTap,
      centerButton: FloatingCenterButton(
        icon: Icons.qr_code_scanner_rounded,
        onTap: onCenterButtonTap ?? () {
          // Default action - could open QR scanner or quick action menu
        },
        backgroundColor: AppConstants.accentColor,
      ),
      items: const [
        AppBottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Home',
        ),
        AppBottomNavItem(
          icon: Icons.sports_martial_arts_outlined,
          activeIcon: Icons.sports_martial_arts_rounded,
          label: 'Classes',
        ),
        AppBottomNavItem(
          icon: Icons.calendar_today_outlined,
          activeIcon: Icons.calendar_today_rounded,
          label: 'Calendar',
        ),
        AppBottomNavItem(
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          label: 'Profile',
        ),
      ],
    );
  }
}