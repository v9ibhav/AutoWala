import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/logger.dart';

class RideCompletedPage extends ConsumerStatefulWidget {
  final String rideId;

  const RideCompletedPage({
    super.key,
    required this.rideId,
  });

  @override
  ConsumerState<RideCompletedPage> createState() => _RideCompletedPageState();
}

class _RideCompletedPageState extends ConsumerState<RideCompletedPage> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingRating = false;
  bool _isLoadingRideDetails = true;

  // Ride details from API
  double? _fare;
  double? _distanceKm;
  int? _durationMinutes;
  String? _paymentMethod;
  String? _riderName;

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
  }

  Future<void> _fetchRideDetails() async {
    try {
      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.get('/rides/${widget.rideId}');

      if (response['success'] == true && response['data'] != null) {
        final rideData = response['data'];

        setState(() {
          _fare = rideData['fare']?.toDouble();
          _distanceKm = rideData['distance_km']?.toDouble();
          _durationMinutes = rideData['duration_minutes']?.toInt();
          _paymentMethod = rideData['payment_method'] ?? 'Cash';
          _riderName = rideData['rider']?['full_name'];
          _isLoadingRideDetails = false;
        });

        AppLogger.debug('Ride details loaded successfully', {
          'ride_id': widget.rideId,
          'fare': _fare,
          'distance_km': _distanceKm,
          'duration_minutes': _durationMinutes,
        });
      }
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch ride details', error, stackTrace, {
        'ride_id': widget.rideId,
      });

      // Set default values on error
      setState(() {
        _fare = 85.0; // Default fallback
        _distanceKm = 4.2;
        _durationMinutes = 18;
        _paymentMethod = 'Cash';
        _isLoadingRideDetails = false;
      });
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingRating = true;
    });

    try {
      // Submit rating to API
      final apiService = ref.read(apiServiceProvider);

      await apiService.post('/rides/${widget.rideId}/rating', {
        'rating': _rating,
        'feedback': _feedbackController.text.isNotEmpty
            ? _feedbackController.text
            : null,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.userAction('rating_submitted', parameters: {
        'ride_id': widget.rideId,
        'rating': _rating,
        'has_feedback': _feedbackController.text.isNotEmpty,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back to home
        context.go('/');
      }
    } catch (e) {
      AppLogger.error('Failed to submit rating', e, null, {
        'ride_id': widget.rideId,
        'rating': _rating,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        title: const Text('Ride Completed'),
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon and message
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: AppBorders.medium,
                  boxShadow: AppShadows.light,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ride Completed!',
                      style: AppTextStyles.h2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you for using AutoWala. Your ride has been completed successfully.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Ride details summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: AppBorders.medium,
                  boxShadow: AppShadows.light,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Details',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Ride ID', widget.rideId),
                    _buildDetailRow(
                        'Fare',
                        _isLoadingRideDetails
                            ? 'Loading...'
                            : '₹${_fare?.toStringAsFixed(2) ?? '85.00'}'),
                    _buildDetailRow('Payment Method', _paymentMethod ?? 'Cash'),
                    _buildDetailRow(
                        'Distance',
                        _isLoadingRideDetails
                            ? 'Loading...'
                            : '${_distanceKm?.toStringAsFixed(1) ?? '4.2'} km'),
                    _buildDetailRow(
                        'Duration',
                        _isLoadingRideDetails
                            ? 'Loading...'
                            : '${_durationMinutes ?? 18} min'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rating section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: AppBorders.medium,
                  boxShadow: AppShadows.light,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate Your Ride',
                      style: AppTextStyles.h4,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How was your experience with your auto-rickshaw driver?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              size: 36,
                              color: AppColors.warning,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Feedback text field
                    TextField(
                      controller: _feedbackController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Additional Feedback (Optional)',
                        hintText: 'Tell us about your experience...',
                        border: OutlineInputBorder(
                          borderRadius: AppBorders.small,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppBorders.small,
                          borderSide: const BorderSide(
                            color: AppColors.accentGreen,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit rating button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmittingRating ? null : _submitRating,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          foregroundColor: AppColors.primaryWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppBorders.small,
                          ),
                        ),
                        child: _isSubmittingRating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryWhite,
                                  ),
                                ),
                              )
                            : Text(
                                'Submit Rating',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primaryWhite,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Book another ride button
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentGreen,
                  side: const BorderSide(color: AppColors.accentGreen),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorders.small,
                  ),
                ),
                child: Text(
                  'Book Another Ride',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray600,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
