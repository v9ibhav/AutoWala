import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';

/// Premium bottom sheet displaying nearby auto-rickshaws
/// Features smooth animations and high-quality card design
class NearbyAutosBottomSheet extends StatefulWidget {
  final List<RiderData> riders;
  final Function(RiderData)? onRiderSelected;
  final VoidCallback? onRefresh;
  final bool isLoading;

  const NearbyAutosBottomSheet({
    super.key,
    required this.riders,
    this.onRiderSelected,
    this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<NearbyAutosBottomSheet> createState() => _NearbyAutosBottomSheetState();
}

class _NearbyAutosBottomSheetState extends State<NearbyAutosBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _cardController;
  final PageController _pageController = PageController(viewportFraction: 0.92);

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideController.forward();
    _cardController.forward();
  }

  void _onRiderTapped(RiderData rider, int index) {
    HapticFeedback.mediumImpact();

    AppLogger.userAction('rider_card_tapped', parameters: {
      'rider_id': rider.id,
      'rider_name': rider.name,
      'distance_km': rider.distanceKm,
      'rating': rider.rating,
    });

    widget.onRiderSelected?.call(rider);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: Offset(0, _slideController.value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            _buildHeader(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.gray300,
        borderRadius: BorderRadius.circular(2),
      ),
    ).animate().fadeIn(delay: 200.ms).scale(delay: 200.ms);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Text(
            'Nearby Auto-Rickshaws',
            style: AppTextStyles.h3,
          ),
          const Spacer(),
          if (widget.isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              ),
            )
          else
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(
                Icons.refresh,
                color: AppColors.gray600,
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0.0);
  }

  Widget _buildContent() {
    if (widget.riders.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: widget.riders.length,
        itemBuilder: (context, index) {
          final rider = widget.riders[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildRiderCard(rider, index),
          );
        },
      ),
    );
  }

  Widget _buildRiderCard(RiderData rider, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
        border: Border.all(
          color: AppColors.gray100,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onRiderTapped(rider, index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRiderHeader(rider),
                const SizedBox(height: 16),
                _buildVehicleInfo(rider),
                const SizedBox(height: 16),
                _buildRideDetails(rider),
                const Spacer(),
                _buildActionButton(rider),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 100 + 400).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0.0, duration: 500.ms, curve: Curves.easeOut);
  }

  Widget _buildRiderHeader(RiderData rider) {
    return Row(
      children: [
        // Profile photo
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.soft,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: rider.profilePhotoUrl != null
                ? CachedNetworkImage(
                    imageUrl: rider.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.gray100,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.gray400,
                        size: 24,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.gray100,
                      child: const Icon(
                        Icons.person,
                        color: AppColors.gray400,
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.gray100,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.gray400,
                      size: 24,
                    ),
                  ),
          ),
        ),

        const SizedBox(width: 16),

        // Rider info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rider.name,
                style: AppTextStyles.h4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${rider.rating}',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${rider.totalRides} trips)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Fare
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${AppConstants.currencySymbol}${rider.farePerPassenger.toInt()}',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'per seat',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(RiderData rider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car_rounded,
            color: AppColors.gray600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.vehicleNumber,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rider.vehicleMake} • ${rider.vehicleColor}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetails(RiderData rider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildDetailItem(
          icon: Icons.location_on_rounded,
          value: '${rider.distanceKm} km',
          label: 'Distance',
        ),
        Container(
          width: 1,
          height: 32,
          color: AppColors.gray200,
        ),
        _buildDetailItem(
          icon: Icons.schedule_rounded,
          value: '${rider.etaMinutes} min',
          label: 'ETA',
        ),
        Container(
          width: 1,
          height: 32,
          color: AppColors.gray200,
        ),
        _buildDetailItem(
          icon: Icons.people_rounded,
          value: '${rider.maxPassengers}',
          label: 'Seats',
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.gray500,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(RiderData rider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _onRiderTapped(rider, 0),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlack,
          foregroundColor: AppColors.primaryWhite,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              'Book This Auto',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primaryWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
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
              Icons.search_off_rounded,
              color: AppColors.gray400,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Auto-Rickshaws Found',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try expanding your search radius or check back in a few minutes.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Search Again'),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

/// Model for rider data displayed in the bottom sheet
class RiderData {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final int totalRides;
  final double farePerPassenger;
  final String vehicleNumber;
  final String vehicleMake;
  final String vehicleColor;
  final int maxPassengers;
  final double distanceKm;
  final int etaMinutes;
  final String? profilePhotoUrl;
  final DateTime lastLocationUpdate;
  final Map<String, dynamic> currentLocation;

  RiderData({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.totalRides,
    required this.farePerPassenger,
    required this.vehicleNumber,
    required this.vehicleMake,
    required this.vehicleColor,
    required this.maxPassengers,
    required this.distanceKm,
    required this.etaMinutes,
    this.profilePhotoUrl,
    required this.lastLocationUpdate,
    required this.currentLocation,
  });

  /// Create RiderData from API response
  factory RiderData.fromJson(Map<String, dynamic> json) {
    return RiderData(
      id: json['id']?.toString() ?? '',
      name: json['full_name']?.toString() ?? 'Driver',
      phoneNumber: json['phone_number']?.toString() ?? '',
      rating: (json['average_rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: json['total_rides'] as int? ?? 0,
      farePerPassenger:
          (json['fare_per_passenger'] as num?)?.toDouble() ?? 30.0,
      vehicleNumber: json['vehicle']?['registration_number']?.toString() ?? '',
      vehicleMake: json['vehicle']?['make']?.toString() ?? 'Auto',
      vehicleColor: json['vehicle']?['color']?.toString() ?? 'Yellow',
      maxPassengers: json['vehicle']?['max_passengers'] as int? ?? 3,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: json['estimated_eta_minutes'] as int? ?? 0,
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      lastLocationUpdate:
          DateTime.tryParse(json['location_updated_at']?.toString() ?? '') ??
              DateTime.now(),
      currentLocation: json['current_location'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Get mock data for testing
  static List<RiderData> getMockData() {
    return [
      RiderData(
        id: '1',
        name: 'Rajesh Kumar',
        phoneNumber: '+919876543210',
        rating: 4.8,
        totalRides: 1247,
        farePerPassenger: 30.0,
        vehicleNumber: 'MH 01 AB 1234',
        vehicleMake: 'Bajaj',
        vehicleColor: 'Yellow',
        maxPassengers: 3,
        distanceKm: 0.8,
        etaMinutes: 3,
        lastLocationUpdate: DateTime.now(),
        currentLocation: {'latitude': 19.0760, 'longitude': 72.8777},
      ),
      RiderData(
        id: '2',
        name: 'Suresh Patel',
        phoneNumber: '+919876543211',
        rating: 4.9,
        totalRides: 892,
        farePerPassenger: 30.0,
        vehicleNumber: 'MH 02 CD 5678',
        vehicleMake: 'Mahindra',
        vehicleColor: 'Green',
        maxPassengers: 3,
        distanceKm: 1.2,
        etaMinutes: 5,
        lastLocationUpdate: DateTime.now(),
        currentLocation: {'latitude': 19.0800, 'longitude': 72.8800},
      ),
      RiderData(
        id: '3',
        name: 'Amit Shah',
        phoneNumber: '+919876543212',
        rating: 4.7,
        totalRides: 645,
        farePerPassenger: 30.0,
        vehicleNumber: 'MH 03 EF 9012',
        vehicleMake: 'Piaggio',
        vehicleColor: 'Black',
        maxPassengers: 3,
        distanceKm: 2.1,
        etaMinutes: 8,
        lastLocationUpdate: DateTime.now(),
        currentLocation: {'latitude': 19.0900, 'longitude': 72.8900},
      ),
    ];
  }
}
