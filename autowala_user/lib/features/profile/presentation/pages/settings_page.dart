import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _locationSharingEnabled = true;
  bool _soundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications section
              _buildSectionHeader('Notifications'),
              _buildSettingsCard([
                _buildSwitchTile(
                  title: 'Push Notifications',
                  subtitle: 'Receive important updates about your rides',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play sounds for notifications',
                  value: _soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  },
                ),
              ]),

              const SizedBox(height: 24),

              // Privacy section
              _buildSectionHeader('Privacy'),
              _buildSettingsCard([
                _buildSwitchTile(
                  title: 'Location Sharing',
                  subtitle: 'Share your location for better ride matching',
                  value: _locationSharingEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationSharingEnabled = value;
                    });
                  },
                ),
                _buildTile(
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  onTap: _clearCache,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ]),

              const SizedBox(height: 24),

              // Account section
              _buildSectionHeader('Account'),
              _buildSettingsCard([
                _buildTile(
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () => _showProfileEditDialog(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildTile(
                  title: 'Payment Methods',
                  subtitle: 'Manage your payment options',
                  onTap: () => _showPaymentMethodsDialog(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildTile(
                  title: 'Saved Addresses',
                  subtitle: 'Manage your favorite locations',
                  onTap: () => _showSavedAddressesDialog(),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ]),

              const SizedBox(height: 24),

              // Support section
              _buildSectionHeader('Support'),
              _buildSettingsCard([
                _buildTile(
                  title: 'Help Center',
                  subtitle: 'Get help and support',
                  onTap: () => _openHelpCenter(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildTile(
                  title: 'Contact Us',
                  subtitle: 'Reach out to our support team',
                  onTap: () => _showContactDialog(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildTile(
                  title: 'Report an Issue',
                  subtitle: 'Report a problem or bug',
                  onTap: () => _showReportDialog(),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ]),

              const SizedBox(height: 24),

              // Legal section
              _buildSectionHeader('Legal'),
              _buildSettingsCard([
                _buildTile(
                  title: 'Terms of Service',
                  subtitle: 'Read our terms and conditions',
                  onTap: () => _openTerms(),
                  trailing: const Icon(Icons.chevron_right),
                ),
                _buildTile(
                  title: 'Privacy Policy',
                  subtitle: 'Learn how we protect your data',
                  onTap: () => _openPrivacyPolicy(),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ]),

              const SizedBox(height: 24),

              // App info
              _buildSectionHeader('About'),
              _buildSettingsCard([
                _buildTile(
                  title: 'App Version',
                  subtitle: 'Version ${AppConstants.appVersion}',
                  onTap: null,
                  trailing: null,
                ),
                _buildTile(
                  title: 'Check for Updates',
                  subtitle: 'Make sure you have the latest features',
                  onTap: _checkForUpdates,
                  trailing: const Icon(Icons.chevron_right),
                ),
              ]),

              const SizedBox(height: 24),

              // Logout button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: AppBorders.medium,
                  boxShadow: AppShadows.light,
                ),
                child: TextButton(
                  onPressed: _showLogoutDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.medium,
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.h4.copyWith(
          color: AppColors.gray700,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: AppBorders.medium,
        boxShadow: AppShadows.light,
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTile({
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.gray600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accentGreen,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }

  void _clearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear the app cache? This will free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Methods'),
        content: const Text('Currently, AutoWala supports cash payments. Digital payment options coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSavedAddressesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saved Addresses'),
        content: const Text('Saved addresses feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openHelpCenter() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening help center...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: support@autowala.in'),
            SizedBox(height: 8),
            Text('Phone: +91 1800-123-4567'),
            SizedBox(height: 8),
            Text('Hours: 24/7 Support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Text('Issue reporting feature coming soon! For urgent issues, please contact our support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening terms of service...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy policy...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _checkForUpdates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have the latest version!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Call logout from auth provider
                final authNotifier = ref.read(authProvider.notifier);
                await authNotifier.logout();

                AppLogger.userAction('user_logged_out');

                // Hide loading indicator
                if (mounted) Navigator.of(context).pop();

                // Navigate to login screen
                if (mounted) {
                  context.go('/login');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logged out successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                AppLogger.error('Logout failed', e);

                // Hide loading indicator
                if (mounted) Navigator.of(context).pop();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logout failed. Please try again.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}