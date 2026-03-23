import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../providers/auth_provider.dart';

/// Premium login screen with OTP authentication
/// Features beautiful animations and optimized for outdoor visibility
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _onSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneNumber = '+91${_phoneController.text.trim()}';

    AppLogger.userAction('login_attempt', parameters: {
      'phone_number': phoneNumber,
      'method': 'otp',
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.sendOTP(phoneNumber);

      if (mounted) {
        Navigator.pushNamed(context, '/otp-verification', arguments: {
          'phoneNumber': phoneNumber,
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      AppLogger.error('login_failed', error: e.toString(), parameters: {
        'phone_number': phoneNumber,
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
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildLoginForm(),
              const SizedBox(height: 32),
              _buildSocialProof(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App logo and branding
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppShadows.medium,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.primaryWhite,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'AutoWala',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primaryWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ).animate().scale(delay: 200.ms, duration: 600.ms),
        ),

        const SizedBox(height: 48),

        // Welcome text
        Text(
          'Welcome to AutoWala',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w800,
          ),
        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0.0),

        const SizedBox(height: 16),

        Text(
          'Find and book auto-rickshaws instantly.\nPay cash directly to the driver.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.gray600,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0.0),
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
            'Enter your mobile number',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 24),

          // Phone number input
          CustomTextField(
            controller: _phoneController,
            hintText: '9876543210',
            label: 'Mobile Number',
            keyboardType: TextInputType.phone,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                '+91',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            validator: Validators.validatePhoneNumber,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            enabled: !_isLoading,
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0.0),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.errorRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().shake(),
          ],

          const SizedBox(height: 32),

          // Send OTP button
          CustomButton(
            onPressed: _isLoading ? null : _onSendOTP,
            isLoading: _isLoading,
            text: 'Send OTP',
            style: CustomButtonStyle.primary,
            icon: Icons.message_rounded,
          ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0.0),

          const SizedBox(height: 24),

          // Terms and conditions
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gray500,
                ),
                children: [
                  const TextSpan(text: 'By continuing, you agree to our '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 1200.ms),
        ],
      ),
    );
  }

  Widget _buildSocialProof() {
    return Column(
      children: [
        const SizedBox(height: 48),

        // Trust indicators
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gray100,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrustIndicator(
                    icon: Icons.security_rounded,
                    title: 'Secure',
                    subtitle: 'OTP Verification',
                  ),
                  _buildTrustIndicator(
                    icon: Icons.payments_rounded,
                    title: 'Cash Only',
                    subtitle: 'No Wallet Needed',
                  ),
                  _buildTrustIndicator(
                    icon: Icons.location_on_rounded,
                    title: 'Real-time',
                    subtitle: 'Live Tracking',
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.2, end: 0.0),

        const SizedBox(height: 32),

        // App version info
        Text(
          'Version ${AppConstants.appVersion}',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray400,
          ),
        ).animate().fadeIn(delay: 1600.ms),
      ],
    );
  }

  Widget _buildTrustIndicator({
    required IconData icon,
    required String title,
    required String subtitle,
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
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
