import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Button sizes for the app button
enum AppButtonSize { small, medium, large }

/// Button variants for the app button
enum AppButtonVariant { primary, secondary, outline, ghost, danger }

/// Customizable button widget with various sizes and variants
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getButtonHeight(),
      child: ElevatedButton(
        onPressed: (isDisabled || isLoading) ? null : onPressed,
        style: _getButtonStyle(),
        child: isLoading
            ? SizedBox(
                width: _getIconSize(),
                height: _getIconSize(),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTextColor(),
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: AppConstants.spaceSm),
                  ],
                  Text(
                    text,
                    style: _getTextStyle(),
                  ),
                ],
              ),
      ),
    );
  }

  double _getButtonHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppConstants.buttonHeightSm;
      case AppButtonSize.medium:
        return AppConstants.buttonHeightMd;
      case AppButtonSize.large:
        return AppConstants.buttonHeightLg;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppConstants.iconSm;
      case AppButtonSize.medium:
        return AppConstants.iconMd;
      case AppButtonSize.large:
        return AppConstants.iconLg;
    }
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case AppButtonSize.small:
        baseStyle = AppConstants.buttonTextSm;
        break;
      case AppButtonSize.medium:
        baseStyle = AppConstants.buttonTextMd;
        break;
      case AppButtonSize.large:
        baseStyle = AppConstants.buttonTextLg;
        break;
    }
    
    return baseStyle.copyWith(color: _getTextColor());
  }

  Color _getTextColor() {
    if (variant == AppButtonVariant.outline || variant == AppButtonVariant.ghost) {
      switch (variant) {
        case AppButtonVariant.outline:
          return AppConstants.primaryColor;
        case AppButtonVariant.ghost:
          return AppConstants.textPrimary;
        default:
          return AppConstants.primaryColor;
      }
    }
    return AppConstants.textOnPrimary;
  }

  ButtonStyle _getButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _getBackgroundColor(),
      foregroundColor: _getTextColor(),
      elevation: _getElevation(),
      shadowColor: AppConstants.primaryColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        side: _getBorderSide(),
      ),
      padding: _getPadding(),
      minimumSize: Size(0, _getButtonHeight()),
    );
  }

  Color _getBackgroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppConstants.primaryColor;
      case AppButtonVariant.secondary:
        return AppConstants.secondaryColor;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.ghost:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppConstants.errorColor;
    }
  }

  double _getElevation() {
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.secondary:
      case AppButtonVariant.danger:
        return AppConstants.elevationSm;
      case AppButtonVariant.outline:
      case AppButtonVariant.ghost:
        return 0;
    }
  }

  BorderSide _getBorderSide() {
    switch (variant) {
      case AppButtonVariant.outline:
        return BorderSide(
          color: AppConstants.primaryColor,
          width: 1.5,
        );
      case AppButtonVariant.ghost:
        return BorderSide.none;
      default:
        return BorderSide.none;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceSm,
        );
      case AppButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        );
      case AppButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceXl,
          vertical: AppConstants.spaceLg,
        );
    }
  }
}