import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ride/presentation/providers/ride_provider.dart';

/// Premium user profile page with account management
/// Features ride history, settings, and profile editing
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late TabController _tabController;

  bool _isEditing = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _rideHistory = [];

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTabController();
    _loadUserData();
    _loadRideHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController.forward();
  }

  void _setupTabController() {
    _tabController = TabController(length: 3, vsync: this);
  }

  void _loadUserData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user['full_name'] ?? '';
      _emailController.text = user['email'] ?? '';
    }
  }

  void _loadRideHistory() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final rideNotifier = ref.read(rideProvider.notifier);
      final history = await rideNotifier.getRideHistory();

      setState(() {
        _rideHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      AppLogger.error('Failed to load ride history', e.toString());
    }
  }

  void _saveProfile() async {
    if (!_isEditing) return;

    HapticFeedback.mediumImpact();

    try {
      setState(() {
        _isLoading = true;
      });

      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.updateProfile({
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppLogger.userAction('profile_updated');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppLogger.error('Failed to update profile', e.toString());
    }
  }

  void _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Logout',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        final authNotifier = ref.read(authProvider.notifier);
        await authNotifier.logout();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to logout: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(user),
                  _buildRideHistoryTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile photo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppShadows.medium,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: user?['profile_photo_url'] != null
                  ? CachedNetworkImage(
                      imageUrl: user!['profile_photo_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.gray100,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gray400,
                          size: 40,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.gray100,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.gray400,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.gray100,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.gray400,
                        size: 40,
                      ),
                    ),
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms),

          const SizedBox(width: 20),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?['full_name'] ?? 'User',
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0.0),
                const SizedBox(height: 4),
                Text(
                  user?['phone_number'] ?? '',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0.0),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Verified User',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).scale(),
              ],
            ),
          ),

          // Edit/Save button
          IconButton(
            onPressed: _isEditing
                ? _saveProfile
                : () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
                    ),
                  )
                : Icon(
                    _isEditing ? Icons.check : Icons.edit,
                    color: AppColors.accentGreen,
                  ),
          ).animate().fadeIn(delay: 1000.ms),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: AppColors.primaryWhite,
        unselectedLabelColor: AppColors.gray600,
        labelStyle: AppTextStyles.labelLarge.copyWith(
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Rides'),
          Tab(text: 'Settings'),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: -0.2, end: 0.0);
  }

  Widget _buildProfileTab(Map<String, dynamic>? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          CustomTextField(
            controller: _nameController,
            label: 'Full Name',
            hintText: 'Enter your full name',
            enabled: _isEditing,
            prefixIcon: const Icon(
              Icons.person_outline,
              color: AppColors.gray500,
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0.0),

          const SizedBox(height: 20),

          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            enabled: _isEditing,
            prefixIcon: const Icon(
              Icons.email_outlined,
              color: AppColors.gray500,
            ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0.0),

          const SizedBox(height: 20),

          CustomTextField(
            controller:
                TextEditingController(text: user?['phone_number'] ?? ''),
            label: 'Phone Number',
            enabled: false,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: AppColors.gray500,
            ),
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0.0),

          const SizedBox(height: 32),

          // Profile stats
          _buildProfileStats(user)
              .animate()
              .fadeIn(delay: 1000.ms)
              .slideY(begin: 0.3, end: 0.0),
        ],
      ),
    );
  }

  Widget _buildProfileStats(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Statistics',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.directions_car_rounded,
                value: '${_rideHistory.length}',
                label: 'Total Rides',
              ),
              _buildStatItem(
                icon: Icons.star_rounded,
                value: '4.9',
                label: 'Avg Rating',
              ),
              _buildStatItem(
                icon: Icons.savings_rounded,
                value:
                    '${AppConstants.currencySymbol}${_calculateTotalSpent()}',
                label: 'Total Spent',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.accentGreen,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRideHistoryTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
        ),
      );
    }

    if (_rideHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.gray400,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Rides Yet',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Book your first ride to see it here.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _rideHistory.length,
      itemBuilder: (context, index) {
        final ride = _rideHistory[index];
        return _buildRideHistoryItem(ride, index);
      },
    );
  }

  Widget _buildRideHistoryItem(Map<String, dynamic> ride, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ride['pickup_address'] ?? 'Pickup Location',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${AppConstants.currencySymbol}${ride['total_amount']?.toInt() ?? 0}',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ride['dropoff_address'] ?? 'Destination',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRideStatusColor(ride['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getRideStatusText(ride['status']),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getRideStatusColor(ride['status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatRideDate(ride['created_at']),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: (index * 100).ms).fadeIn().slideY(begin: 0.2, end: 0.0);
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage ride and app notifications',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0.0),
          _buildSettingItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0.0),
          _buildSettingItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () {
              // TODO: Navigate to terms of service
            },
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0.0),
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // TODO: Navigate to support
            },
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0.0),
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version ${AppConstants.appVersion}',
            onTap: () {
              // TODO: Show about dialog
            },
          ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0.0),
          const SizedBox(height: 32),
          CustomButton(
            onPressed: _logout,
            text: 'Logout',
            style: CustomButtonStyle.danger,
            icon: Icons.logout_rounded,
          ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.3, end: 0.0),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.gray600,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRideStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return AppColors.accentGreen;
      case 'cancelled':
        return AppColors.errorRed;
      case 'in_progress':
        return Colors.orange;
      default:
        return AppColors.gray500;
    }
  }

  String _getRideStatusText(String? status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Unknown';
    }
  }

  String _formatRideDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  int _calculateTotalSpent() {
    return _rideHistory
        .where((ride) => ride['status'] == 'completed')
        .map((ride) => (ride['total_amount'] as num?)?.toInt() ?? 0)
        .fold(0, (sum, amount) => sum + amount);
  }
}
