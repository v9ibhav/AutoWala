import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/rider_theme.dart';
import '../../../../core/utils/rider_constants.dart';

/// Simple and clean login page for riders
/// Focused on essential functionality without distractions
class RiderLoginPage extends ConsumerStatefulWidget {
  const RiderLoginPage({super.key});

  @override
  ConsumerState<RiderLoginPage> createState() => _RiderLoginPageState();
}

class _RiderLoginPageState extends ConsumerState<RiderLoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Implement authentication
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RiderColors.primaryWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: RiderSpacing.screenPadding,
            vertical: RiderSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: RiderSpacing.xxl),
              _buildLoginForm(),
              const SizedBox(height: RiderSpacing.xl),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // App icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: RiderColors.primaryGreen,
            borderRadius: BorderRadius.circular(RiderRadius.xl),
            boxShadow: RiderShadows.medium,
          ),
          child: const Icon(
            Icons.local_taxi_rounded,
            color: RiderColors.primaryWhite,
            size: 50,
          ),
        ).animate().scale(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: RiderSpacing.lg),

        // App name
        Text(
          RiderConstants.appName,
          style: RiderTextStyles.h1.copyWith(color: RiderColors.primaryGreen),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0.0),

        const SizedBox(height: RiderSpacing.sm),

        // Subtitle
        Text(
          'Simple. Clean. Professional.',
          style: RiderTextStyles.bodyLarge.copyWith(
            color: RiderColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0.0),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Login with your mobile number',
            style: RiderTextStyles.h3,
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: RiderSpacing.lg),

          // Phone input
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: RiderTextStyles.bodyLarge,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              hintText: '9876543210',
              prefixIcon: Container(
                padding: const EdgeInsets.all(RiderSpacing.md),
                child: Text(
                  '+91',
                  style: RiderTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              suffixIcon:
                  _phoneController.text.isNotEmpty
                      ? const Icon(
                        Icons.check_circle,
                        color: RiderColors.onlineGreen,
                      )
                      : null,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your mobile number';
              }
              if (value.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
              if (!RegExp(RiderConstants.phoneRegex).hasMatch(value)) {
                return 'Please enter a valid Indian mobile number';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {}); // Update suffix icon
            },
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0.0),

          if (_errorMessage != null) ...[
            const SizedBox(height: RiderSpacing.md),
            Container(
              padding: const EdgeInsets.all(RiderSpacing.md),
              decoration: BoxDecoration(
                color: RiderColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(RiderRadius.md),
                border: Border.all(
                  color: RiderColors.errorRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: RiderColors.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: RiderSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: RiderTextStyles.bodyMedium.copyWith(
                        color: RiderColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().shake(),
          ],

          const SizedBox(height: RiderSpacing.xl),

          // Login button
          SizedBox(
            width: double.infinity,
            height: RiderConstants.buttonHeight,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: RiderColors.primaryGreen,
                foregroundColor: RiderColors.primaryWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RiderRadius.md),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            RiderColors.primaryWhite,
                          ),
                        ),
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.login, size: 20),
                          const SizedBox(width: RiderSpacing.sm),
                          Text(
                            'Login with OTP',
                            style: RiderTextStyles.buttonText.copyWith(
                              color: RiderColors.primaryWhite,
                            ),
                          ),
                        ],
                      ),
            ),
          ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3, end: 0.0),

          const SizedBox(height: RiderSpacing.lg),

          // Terms agreement
          Center(
            child: Text(
              'By logging in, you agree to our Terms of Service\nand Privacy Policy for drivers.',
              style: RiderTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(delay: 1400.ms),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Support info
        Container(
          padding: const EdgeInsets.all(RiderSpacing.lg),
          decoration: BoxDecoration(
            color: RiderColors.surfaceGray,
            borderRadius: BorderRadius.circular(RiderRadius.lg),
          ),
          child: Column(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: RiderColors.primaryGreen,
                size: 32,
              ),
              const SizedBox(height: RiderSpacing.sm),
              Text(
                'Need Help?',
                style: RiderTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: RiderSpacing.xs),
              Text(
                'Call our driver support: 1800-123-4567',
                style: RiderTextStyles.bodyMedium.copyWith(
                  color: RiderColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate().fadeIn(delay: 1600.ms).slideY(begin: 0.2, end: 0.0),

        const SizedBox(height: RiderSpacing.lg),

        // Version info
        Text(
          'Version ${RiderConstants.appVersion}',
          style: RiderTextStyles.caption,
        ).animate().fadeIn(delay: 1800.ms),
      ],
    );
  }
}
