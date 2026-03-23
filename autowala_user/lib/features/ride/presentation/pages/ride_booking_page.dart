import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../home/presentation/widgets/nearby_autos_bottom_sheet.dart';
import '../providers/ride_provider.dart';

/// Premium ride booking confirmation page
/// Shows rider details, fare estimate, and booking confirmation
class RideBookingPage extends ConsumerStatefulWidget {
  final RiderData rider;
  final Map<String, dynamic> pickupLocation;
  final Map<String, dynamic> dropoffLocation;

  const RideBookingPage({
    super.key,
    required this.rider,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  ConsumerState<RideBookingPage> createState() => _RideBookingPageState();
}

class _RideBookingPageState extends ConsumerState<RideBookingPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;

  bool _isBooking = false;
  String? _errorMessage;
  int _passengerCount = 1;
  String? _additionalNotes;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  void _bookRide() async {
    HapticFeedback.mediumImpact();

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    AppLogger.userAction('ride_booking_initiated', parameters: {
      'rider_id': widget.rider.id,
      'passenger_count': _passengerCount,
      'pickup_lat': widget.pickupLocation['latitude'],
      'pickup_lon': widget.pickupLocation['longitude'],
      'dropoff_lat': widget.dropoffLocation['latitude'],
      'dropoff_lon': widget.dropoffLocation['longitude'],
    });

    try {
      final rideNotifier = ref.read(rideProvider.notifier);
      await rideNotifier.bookRide(
        riderId: widget.rider.id,
        pickupLocation: widget.pickupLocation,
        dropoffLocation: widget.dropoffLocation,
        passengerCount: _passengerCount,
        additionalNotes: _additionalNotes,
      );

      if (mounted) {
        // Navigate to ride tracking page
        Navigator.pushReplacementNamed(
          context,
          '/ride-tracking',
          arguments: {
            'rider': widget.rider,
            'rideData': ref.read(rideProvider).currentRide,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      AppLogger.error('ride_booking_failed', error: e.toString(), parameters: {
        'rider_id': widget.rider.id,
        'passenger_count': _passengerCount,
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
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
        title: Text(
          'Confirm Booking',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primaryBlack,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiderInfo(),
                    const SizedBox(height: 24),
                    _buildLocationInfo(),
                    const SizedBox(height: 24),
                    _buildRideOptions(),
                    const SizedBox(height: 24),
                    _buildFareBreakdown(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 24),
                      _buildErrorMessage(),
                    ],
                  ],
                ),
              ),
            ),
            _buildBookingActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: Border.all(
          color: AppColors.gray100,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile photo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.soft,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: widget.rider.profilePhotoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.rider.profilePhotoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.gray400,
                              size: 30,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.gray100,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.gray400,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.gray100,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.gray400,
                            size: 30,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Rider details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.rider.name,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.rider.rating}',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${widget.rider.totalRides} trips)',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.rider.vehicleNumber} • ${widget.rider.vehicleMake}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ETA badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.rider.etaMinutes}',
                      style: AppTextStyles.h4.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'mins',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                color: AppColors.accentGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Trip Details',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pickup location
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.pickupLocation['address'] ?? 'Current Location',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Connection line
          Container(
            margin: const EdgeInsets.only(left: 6, top: 8, bottom: 8),
            width: 2,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          // Dropoff location
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dropoff',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.dropoffLocation['address'] ?? 'Destination',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Distance and duration
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '${widget.rider.distanceKm} km',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Distance',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.gray200,
                ),
                Column(
                  children: [
                    Text(
                      '${widget.rider.etaMinutes} min',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Duration',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildRideOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Options',
            style: AppTextStyles.h4.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // Passenger count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of passengers',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _passengerCount > 1
                        ? () {
                            setState(() {
                              _passengerCount--;
                            });
                            HapticFeedback.lightImpact();
                          }
                        : null,
                    icon: Icon(
                      Icons.remove_circle,
                      color: _passengerCount > 1
                          ? AppColors.primaryBlack
                          : AppColors.gray300,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_passengerCount',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _passengerCount < widget.rider.maxPassengers
                        ? () {
                            setState(() {
                              _passengerCount++;
                            });
                            HapticFeedback.lightImpact();
                          }
                        : null,
                    icon: Icon(
                      Icons.add_circle,
                      color: _passengerCount < widget.rider.maxPassengers
                          ? AppColors.primaryBlack
                          : AppColors.gray300,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Max ${widget.rider.maxPassengers} passengers allowed',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildFareBreakdown() {
    final totalFare = widget.rider.farePerPassenger * _passengerCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fare Details',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.accentGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base fare per passenger',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray700,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${widget.rider.farePerPassenger.toInt()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Number of passengers',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray700,
                ),
              ),
              Text(
                '×$_passengerCount',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.accentGreen.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${totalFare.toInt()}',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  color: AppColors.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You\'ll pay cash directly to the driver',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0.0);
  }

  Widget _buildErrorMessage() {
    return Container(
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
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildBookingActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomButton(
            onPressed: _isBooking ? null : _bookRide,
            isLoading: _isBooking,
            text: 'Confirm Booking',
            style: CustomButtonStyle.primary,
            icon: Icons.check_circle_rounded,
          ),
          const SizedBox(height: 12),
          CustomButton(
            onPressed: () => Navigator.pop(context),
            text: 'Cancel',
            style: CustomButtonStyle.ghost,
            icon: Icons.close_rounded,
          ),
        ],
      ),
    ).animate().slideY(begin: 1.0, end: 0.0, delay: 1000.ms);
  }
}
