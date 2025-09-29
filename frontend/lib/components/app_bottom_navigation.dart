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
      // No margins - full width and extends to bottom
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: NavBarClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 90, // Increased height to extend further down
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
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20), // Push content up from bottom
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
              top: -5, // Adjusted to match new notch position
              left: MediaQuery.of(context).size.width / 2 - 30,
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
/// Creates a continuous navigation bar across full width with a central circular notch.

class NavBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppConstants.surfaceColor.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // First, draw the main rectangle (full strip)
    final mainRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.circular(AppConstants.radiusXl),
      topRight: Radius.circular(AppConstants.radiusXl),
    );
    canvas.drawRRect(mainRect, paint);
    
    // Then, cut out the circle by drawing it with BlendMode.clear
    final centerX = size.width / 2;
    final centerY = size.height - 25; // Circle center position
    final radius = 30.0;
    
    final circlePaint = Paint()
      ..blendMode = BlendMode.clear;
    
    canvas.drawCircle(Offset(centerX, centerY), radius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NavBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final radius = 30.0;
    
    // Create main rectangle (full width strip)
    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    // Add rounded corners at the top only
    final roundedPath = Path();
    roundedPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: Radius.circular(AppConstants.radiusXl),
      topRight: Radius.circular(AppConstants.radiusXl),
    ));
    
    // Create circular cutout positioned further below the bottom edge
    final circlePath = Path();
    circlePath.addOval(Rect.fromCircle(
      center: Offset(centerX, size.height + 25), // Circle center further below bottom edge
      radius: radius,
    ));
    
    // Combine: Start with rounded rectangle, then subtract circle
    final result = Path.combine(PathOperation.difference, roundedPath, circlePath);
    
    return result;
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