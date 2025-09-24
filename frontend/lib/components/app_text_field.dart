import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Text field sizes for the app text field
enum AppTextFieldSize { small, medium, large }

/// Customizable text field widget with various sizes and features
class AppTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final AppTextFieldSize size;
  final bool required;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.size = AppTextFieldSize.medium,
    this.required = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          RichText(
            text: TextSpan(
              text: widget.label!,
              style: AppConstants.labelMd,
              children: [
                if (widget.required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppConstants.errorColor),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppConstants.spaceSm),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onEditingComplete: widget.onEditingComplete,
            style: _getTextStyle(),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppConstants.bodyMd.copyWith(
                color: AppConstants.textTertiary,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              contentPadding: _getContentPadding(),
              filled: true,
              fillColor: widget.enabled 
                  ? AppConstants.surfaceColor 
                  : AppConstants.grey100,
              border: _getBorder(AppConstants.grey300),
              enabledBorder: _getBorder(AppConstants.grey300),
              focusedBorder: _getBorder(AppConstants.primaryColor),
              errorBorder: _getBorder(AppConstants.errorColor),
              focusedErrorBorder: _getBorder(AppConstants.errorColor),
              disabledBorder: _getBorder(AppConstants.grey200),
              errorText: widget.errorText,
              errorStyle: AppConstants.bodyXs.copyWith(
                color: AppConstants.errorColor,
              ),
              counterStyle: AppConstants.bodyXs,
            ),
          ),
        ),
        if (widget.helperText != null && widget.errorText == null) ...[
          SizedBox(height: AppConstants.spaceXs),
          Text(
            widget.helperText!,
            style: AppConstants.bodyXs.copyWith(
              color: AppConstants.textPrimary,
            ),
          ),
        ],
      ],
    );
  }

  TextStyle _getTextStyle() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return AppConstants.bodySm;
      case AppTextFieldSize.medium:
        return AppConstants.bodyMd;
      case AppTextFieldSize.large:
        return AppConstants.bodyLg;
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case AppTextFieldSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceSm,
        );
      case AppTextFieldSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceMd,
        );
      case AppTextFieldSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceLg,
        );
    }
  }

  OutlineInputBorder _getBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      borderSide: BorderSide(
        color: color,
        width: _isFocused ? 2.0 : 1.0,
      ),
    );
  }
}