import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';

class MapControlsWidget extends StatelessWidget {
  final VoidCallback? onCurrentLocationPressed;
  final VoidCallback? onZoomInPressed;
  final VoidCallback? onZoomOutPressed;
  final VoidCallback? onMenuPressed;
  final bool isLoading;

  const MapControlsWidget({
    super.key,
    this.onCurrentLocationPressed,
    this.onZoomInPressed,
    this.onZoomOutPressed,
    this.onMenuPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Menu button
        if (onMenuPressed != null)
          _buildControlButton(
            icon: Icons.menu,
            onPressed: onMenuPressed,
          ),

        const SizedBox(height: 8),

        // Zoom in button
        if (onZoomInPressed != null)
          _buildControlButton(
            icon: Icons.add,
            onPressed: onZoomInPressed,
          ),

        const SizedBox(height: 8),

        // Zoom out button
        if (onZoomOutPressed != null)
          _buildControlButton(
            icon: Icons.remove,
            onPressed: onZoomOutPressed,
          ),

        const SizedBox(height: 8),

        // Current location button
        if (onCurrentLocationPressed != null)
          _buildControlButton(
            icon: isLoading ? null : Icons.my_location,
            onPressed: isLoading ? null : onCurrentLocationPressed,
            child: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.accentGreen,
                      ),
                    ),
                  )
                : null,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    IconData? icon,
    VoidCallback? onPressed,
    Widget? child,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: child ??
              Icon(
                icon,
                color: onPressed != null
                    ? AppColors.primaryBlack
                    : AppColors.gray400,
                size: 24,
              ),
        ),
      ),
    );
  }
}