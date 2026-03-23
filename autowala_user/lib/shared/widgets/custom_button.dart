import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

/// Button styles for different use cases
enum CustomButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
  danger,
}

/// Premium custom button with animations and multiple styles
class CustomButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final CustomButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double? height;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.style = CustomButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.height,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isFullWidth ? double.infinity : null,
              height: widget.height ?? 56,
              decoration: BoxDecoration(
                color: isEnabled
                    ? buttonStyle.backgroundColor
                    : buttonStyle.disabledBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: buttonStyle.border,
                boxShadow: isEnabled ? buttonStyle.boxShadow : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                    child: _buildButtonContent(buttonStyle, isEnabled),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent(_ButtonStyleData buttonStyle, bool isEnabled) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(buttonStyle.foregroundColor),
          ),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            size: 20,
            color: isEnabled
                ? buttonStyle.foregroundColor
                : buttonStyle.disabledForegroundColor,
          ),
          const SizedBox(width: 12),
          Text(
            widget.text,
            style: AppTextStyles.labelLarge.copyWith(
              color: isEnabled
                  ? buttonStyle.foregroundColor
                  : buttonStyle.disabledForegroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        widget.text,
        style: AppTextStyles.labelLarge.copyWith(
          color: isEnabled
              ? buttonStyle.foregroundColor
              : buttonStyle.disabledForegroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ButtonStyleData _getButtonStyle() {
    switch (widget.style) {
      case CustomButtonStyle.primary:
        return _ButtonStyleData(
          backgroundColor: AppColors.primaryBlack,
          foregroundColor: AppColors.primaryWhite,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          boxShadow: AppShadows.medium,
        );

      case CustomButtonStyle.secondary:
        return _ButtonStyleData(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.primaryWhite,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          boxShadow: AppShadows.medium,
        );

      case CustomButtonStyle.outline:
        return _ButtonStyleData(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryBlack,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.gray400,
          border: Border.all(
            color: AppColors.primaryBlack,
            width: 2,
          ),
        );

      case CustomButtonStyle.ghost:
        return _ButtonStyleData(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.gray600,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.gray400,
        );

      case CustomButtonStyle.danger:
        return _ButtonStyleData(
          backgroundColor: AppColors.errorRed,
          foregroundColor: AppColors.primaryWhite,
          disabledBackgroundColor: AppColors.gray200,
          disabledForegroundColor: AppColors.gray400,
          boxShadow: AppShadows.medium,
        );
    }
  }
}

/// Internal button style data class
class _ButtonStyleData {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color disabledBackgroundColor;
  final Color disabledForegroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  _ButtonStyleData({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.disabledBackgroundColor,
    required this.disabledForegroundColor,
    this.border,
    this.boxShadow,
  });
}
