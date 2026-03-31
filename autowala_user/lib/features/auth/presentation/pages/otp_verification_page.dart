import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/auth_provider.dart';

/// Premium OTP verification screen with pin input
/// Features auto-detecting SMS and resend functionality
class OTPVerificationPage extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  ConsumerState<OTPVerificationPage> createState() =>
      _OTPVerificationPageState();
}

class _OTPVerificationPageState extends ConsumerState<OTPVerificationPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shakeController;

  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startResendTimer();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _resendTimer?.cancel();

    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController.forward();
  }

  void _startResendTimer() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _onOTPChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all fields are filled
    if (index == 5 && value.isNotEmpty) {
      _verifyOTP();
    }
  }

  void _verifyOTP() async {
    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    AppLogger.userAction('otp_verification_attempt', parameters: {
      'phone_number': widget.phoneNumber,
      'otp_length': otp.length,
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.verifyOTP(widget.phoneNumber, otp);

      if (mounted) {
        // Navigate to home or onboarding based on user state
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString());
      _clearOTP();
      _shakeController.forward().then((_) => _shakeController.reset());

      AppLogger.error('otp_verification_failed',
          error: e.toString(),
          parameters: {
            'phone_number': widget.phoneNumber,
          });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Clear error after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _clearOTP() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  void _resendOTP() async {
    if (_isResending || _resendCountdown > 0) return;

    HapticFeedback.lightImpact();

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.sendOTP(widget.phoneNumber);

      setState(() {
        _resendCountdown = 30;
      });
      _startResendTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      AppLogger.userAction('otp_resent', parameters: {
        'phone_number': widget.phoneNumber,
      });
    } catch (e) {
      _showError('Failed to resend OTP. Please try again.');

      AppLogger.error('otp_resend_failed', e.toString(), parameters: {
        'phone_number': widget.phoneNumber,
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primaryBlack,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: 48),
              _buildOTPInput(),
              const SizedBox(height: 32),
              _buildActions(),
              const SizedBox(height: 24),
              _buildResendOption(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // OTP illustration
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(60),
          ),
          child: const Icon(
            Icons.message_rounded,
            size: 60,
            color: AppColors.accentGreen,
          ),
        ).animate().scale(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: 32),

        Text(
          'Verify your number',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0.0),

        const SizedBox(height: 16),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.gray600,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: widget.phoneNumber,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0.0),
      ],
    );
  }

  Widget _buildOTPInput() {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        double shake = _shakeController.value * 10;
        return Transform.translate(
          offset: Offset(shake * (1 - 2 * (_shakeController.value % 0.5)), 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return Container(
                    width: 48,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _otpControllers[index].text.isNotEmpty
                            ? AppColors.accentGreen
                            : _errorMessage != null
                                ? AppColors.errorRed
                                : AppColors.gray300,
                        width: 2,
                      ),
                      boxShadow: _otpControllers[index].text.isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.accentGreen.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : AppShadows.soft,
                    ),
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primaryBlack,
                        fontWeight: FontWeight.w700,
                      ),
                      keyboardType: TextInputType.number,
                      enabled: !_isLoading,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) => _onOTPChanged(index, value),
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0.0),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.errorRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0.0),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        CustomButton(
          onPressed: _isLoading ? null : _verifyOTP,
          isLoading: _isLoading,
          text: 'Verify OTP',
          style: CustomButtonStyle.primary,
          icon: Icons.check_circle_rounded,
        ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3, end: 0.0),
        const SizedBox(height: 16),
        CustomButton(
          onPressed: _clearOTP,
          text: 'Clear',
          style: CustomButtonStyle.ghost,
          icon: Icons.clear_rounded,
        ).animate().fadeIn(delay: 1200.ms),
      ],
    );
  }

  Widget _buildResendOption() {
    return Column(
      children: [
        if (_resendCountdown > 0) ...[
          Text(
            'Resend OTP in $_resendCountdown seconds',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Didn\'t receive the code? ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray500,
                ),
              ),
              GestureDetector(
                onTap: _resendOTP,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Change number option
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 8),
                Text(
                  'Change phone number',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1400.ms);
  }
}
