import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/rider_theme.dart';
import '../../../../core/utils/rider_constants.dart';

/// Simple and clean dashboard for riders
/// Central hub for going online/offline and managing rides
class RiderDashboardPage extends ConsumerStatefulWidget {
  const RiderDashboardPage({super.key});

  @override
  ConsumerState<RiderDashboardPage> createState() => _RiderDashboardPageState();
}

class _RiderDashboardPageState extends ConsumerState<RiderDashboardPage> {
  String _riderStatus = RiderConstants.statusOffline;
  bool _isStatusChanging = false;
  int _todaysRides = 8;
  double _todaysEarnings = 1250.0;
  int _totalRides = 247;
  double _rating = 4.8;

  void _toggleOnlineStatus() async {
    if (_isStatusChanging) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isStatusChanging = true;
    });

    try {
      // TODO: Implement status change API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _riderStatus =
            _riderStatus == RiderConstants.statusOffline
                ? RiderConstants.statusOnline
                : RiderConstants.statusOffline;
      });

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _riderStatus == RiderConstants.statusOnline
                ? RiderConstants.onlineSuccessMessage
                : RiderConstants.offlineSuccessMessage,
          ),
          backgroundColor:
              _riderStatus == RiderConstants.statusOnline
                  ? RiderColors.onlineGreen
                  : RiderColors.offlineGray,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RiderRadius.md),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update status. Please try again.'),
          backgroundColor: RiderColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RiderRadius.md),
          ),
        ),
      );
    } finally {
      setState(() {
        _isStatusChanging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.primaryWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(RiderSpacing.screenPadding),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: RiderSpacing.lg),
                    _buildStatsGrid(),
                    const SizedBox(height: RiderSpacing.lg),
                    _buildQuickActions(),
                    const SizedBox(height: RiderSpacing.lg),
                    _buildTodaysActivity(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(RiderSpacing.screenPadding),
      decoration: const BoxDecoration(
        color: RiderColors.primaryWhite,
        boxShadow: RiderShadows.soft,
      ),
      child: Row(
        children: [
          // Profile avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RiderColors.surfaceGray,
              borderRadius: BorderRadius.circular(RiderRadius.full),
            ),
            child: const Icon(
              Icons.person,
              color: RiderColors.textSecondary,
              size: 24,
            ),
          ).animate().scale(delay: 200.ms),

          const SizedBox(width: RiderSpacing.md),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Rajesh!',
                  style: RiderTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0.0),
                Text(
                  'MH 01 AB 1234',
                  style: RiderTextStyles.bodyMedium.copyWith(
                    color: RiderColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0.0),
              ],
            ),
          ),

          // Notification button
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: const Icon(
              Icons.notifications_outlined,
              color: RiderColors.textSecondary,
            ),
          ).animate().fadeIn(delay: 800.ms),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isOnline = _riderStatus == RiderConstants.statusOnline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(RiderSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isOnline ? RiderColors.onlineGreen : RiderColors.offlineGray,
        borderRadius: BorderRadius.circular(RiderRadius.lg),
        boxShadow: RiderShadows.card,
      ),
      child: Column(
        children: [
          Icon(
            isOnline
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: RiderColors.primaryWhite,
            size: 48,
          ),

          const SizedBox(height: RiderSpacing.md),

          Text(
            isOnline ? 'You are ONLINE' : 'You are OFFLINE',
            style: RiderTextStyles.h2.copyWith(
              color: RiderColors.primaryWhite,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: RiderSpacing.sm),

          Text(
            isOnline
                ? 'Ready to accept rides'
                : 'Tap to go online and start earning',
            style: RiderTextStyles.bodyLarge.copyWith(
              color: RiderColors.primaryWhite.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: RiderSpacing.lg),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isStatusChanging ? null : _toggleOnlineStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.primaryWhite,
                foregroundColor:
                    isOnline
                        ? RiderColors.onlineGreen
                        : RiderColors.offlineGray,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RiderRadius.md),
                ),
              ),
              child:
                  _isStatusChanging
                      ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isOnline
                                ? RiderColors.onlineGreen
                                : RiderColors.offlineGray,
                          ),
                        ),
                      )
                      : Text(
                        isOnline ? 'Go Offline' : 'Go Online',
                        style: RiderTextStyles.buttonText.copyWith(
                          color:
                              isOnline
                                  ? RiderColors.onlineGreen
                                  : RiderColors.offlineGray,
                        ),
                      ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_car,
            value: '$_todaysRides',
            label: 'Today\'s Rides',
            color: RiderColors.primaryGreen,
          ),
        ),
        const SizedBox(width: RiderSpacing.md),
        Expanded(
          child: _buildStatCard(
            icon: Icons.currency_rupee,
            value: '${_todaysEarnings.toInt()}',
            label: 'Today\'s Earnings',
            color: RiderColors.warningOrange,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(RiderSpacing.lg),
      decoration: BoxDecoration(
        color: RiderColors.cardBackground,
        borderRadius: BorderRadius.circular(RiderRadius.lg),
        border: Border.all(color: RiderColors.border),
        boxShadow: RiderShadows.soft,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: RiderSpacing.sm),
          Text(
            value,
            style: RiderTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            style: RiderTextStyles.bodySmall.copyWith(
              color: RiderColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(RiderSpacing.lg),
      decoration: BoxDecoration(
        color: RiderColors.cardBackground,
        borderRadius: BorderRadius.circular(RiderRadius.lg),
        border: Border.all(color: RiderColors.border),
        boxShadow: RiderShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: RiderTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: RiderSpacing.md),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.route,
                  label: 'My Routes',
                  onTap: () {
                    // TODO: Navigate to routes
                  },
                ),
              ),
              const SizedBox(width: RiderSpacing.md),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  label: 'Ride History',
                  onTap: () {
                    // TODO: Navigate to ride history
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: RiderSpacing.md),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.account_circle,
                  label: 'Profile',
                  onTap: () {
                    // TODO: Navigate to profile
                  },
                ),
              ),
              const SizedBox(width: RiderSpacing.md),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.help_outline,
                  label: 'Support',
                  onTap: () {
                    // TODO: Navigate to support
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RiderRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: RiderSpacing.md,
            horizontal: RiderSpacing.sm,
          ),
          child: Column(
            children: [
              Icon(icon, color: RiderColors.textSecondary, size: 32),
              const SizedBox(height: RiderSpacing.xs),
              Text(
                label,
                style: RiderTextStyles.labelMedium.copyWith(
                  color: RiderColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysActivity() {
    return Container(
      padding: const EdgeInsets.all(RiderSpacing.lg),
      decoration: BoxDecoration(
        color: RiderColors.cardBackground,
        borderRadius: BorderRadius.circular(RiderRadius.lg),
        border: Border.all(color: RiderColors.border),
        boxShadow: RiderShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Summary',
                style: RiderTextStyles.h4.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RiderSpacing.sm,
                  vertical: RiderSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: RiderColors.onlineGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(RiderRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: RiderColors.warningOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_rating',
                      style: RiderTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: RiderSpacing.md),

          Row(
            children: [
              Icon(Icons.timer, color: RiderColors.textSecondary, size: 16),
              const SizedBox(width: RiderSpacing.xs),
              Text(
                'Online for 6h 30m',
                style: RiderTextStyles.bodyMedium.copyWith(
                  color: RiderColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: RiderSpacing.sm),

          Row(
            children: [
              Icon(
                Icons.location_on,
                color: RiderColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: RiderSpacing.xs),
              Text(
                'Total distance: 85 km',
                style: RiderTextStyles.bodyMedium.copyWith(
                  color: RiderColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: RiderSpacing.screenPadding,
        vertical: RiderSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: RiderColors.primaryWhite,
        boxShadow: RiderShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildNavItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              isActive: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.route,
              label: 'Routes',
              isActive: false,
              onTap: () {
                // TODO: Navigate to routes
              },
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.history,
              label: 'History',
              isActive: false,
              onTap: () {
                // TODO: Navigate to history
              },
            ),
          ),
          Expanded(
            child: _buildNavItem(
              icon: Icons.person,
              label: 'Profile',
              isActive: false,
              onTap: () {
                // TODO: Navigate to profile
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RiderRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: RiderSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isActive ? RiderColors.primaryGreen : RiderColors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: RiderTextStyles.labelSmall.copyWith(
                  color:
                      isActive
                          ? RiderColors.primaryGreen
                          : RiderColors.textMuted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
