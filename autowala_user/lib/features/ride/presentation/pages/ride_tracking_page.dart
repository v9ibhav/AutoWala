import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/location_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../home/presentation/widgets/nearby_autos_bottom_sheet.dart';
import '../providers/ride_provider.dart';

/// Premium ride tracking page with live GPS tracking
/// Shows real-time rider location and trip progress
class RideTrackingPage extends ConsumerStatefulWidget {
  final RiderData rider;
  final Map<String, dynamic> rideData;

  const RideTrackingPage({
    super.key,
    required this.rider,
    required this.rideData,
  });

  @override
  ConsumerState<RideTrackingPage> createState() => _RideTrackingPageState();
}

class _RideTrackingPageState extends ConsumerState<RideTrackingPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _userLocation;
  LatLng? _riderLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;

  String _rideStatus = 'booked';
  bool _isMapReady = false;
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeRideTracking();
    _startStatusChecking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController.forward();
  }

  void _initializeRideTracking() async {
    try {
      // Set initial locations from ride data
      _pickupLocation = LatLng(
        widget.rideData['pickup_lat'],
        widget.rideData['pickup_lon'],
      );

      _dropoffLocation = LatLng(
        widget.rideData['dropoff_lat'],
        widget.rideData['dropoff_lon'],
      );

      // Get user's current location
      final locationService = ref.read(locationServiceProvider);
      final userPos = await locationService.getCurrentLocation();

      _userLocation = LatLng(userPos.latitude, userPos.longitude);
      _rideStatus = widget.rideData['status'] ?? 'booked';

      _updateMarkers();
    } catch (e) {
      AppLogger.error('Failed to initialize ride tracking',
          error: e.toString());
    }
  }

  void _startStatusChecking() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _checkRideStatus();
      }
    });
  }

  void _checkRideStatus() async {
    try {
      final rideNotifier = ref.read(rideProvider.notifier);
      await rideNotifier.getCurrentRide();
    } catch (e) {
      AppLogger.error('Failed to check ride status', error: e.toString());
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;
    _updateCamera();
  }

  void _updateMarkers() {
    _markers.clear();

    // User location marker
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Pickup location marker
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup_location'),
          position: _pickupLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    // Dropoff location marker
    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff_location'),
          position: _dropoffLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }

    // Rider location marker (if available)
    if (_riderLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('rider_location'),
          position: _riderLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: widget.rider.name,
            snippet:
                '${widget.rider.vehicleNumber} • ${widget.rider.vehicleMake}',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _updateCamera() {
    if (!_isMapReady || _mapController == null) return;

    List<LatLng> points = [];

    if (_userLocation != null) points.add(_userLocation!);
    if (_riderLocation != null) points.add(_riderLocation!);
    if (_pickupLocation != null) points.add(_pickupLocation!);
    if (_dropoffLocation != null) points.add(_dropoffLocation!);

    if (points.isNotEmpty) {
      _fitMarkersInView(points);
    }
  }

  void _fitMarkersInView(List<LatLng> points) {
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (LatLng point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }

  void _cancelRide() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Ride',
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to cancel this ride?',
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Keep Ride',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.gray600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Cancel Ride',
              style:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      try {
        final rideNotifier = ref.read(rideProvider.notifier);
        await rideNotifier.cancelRide(widget.rideData['id'].toString());

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel ride: ${e.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to live tracking updates
    ref.listen<Map<String, dynamic>?>(liveTrackingProvider, (previous, next) {
      if (next != null) {
        final riderLat = next['current_rider_lat'] as double?;
        final riderLon = next['current_rider_lon'] as double?;
        final status = next['status'] as String?;

        if (riderLat != null && riderLon != null) {
          _riderLocation = LatLng(riderLat, riderLon);
          _updateMarkers();
          _updateCamera();
        }

        if (status != null && status != _rideStatus) {
          setState(() {
            _rideStatus = status;
          });

          // Show status change notification
          HapticFeedback.mediumImpact();
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildMapView(),
            ),
            _buildRideInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.primaryBlack,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _getStatusSubtitle(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusIndicator(),
        ],
      ),
    ).animate().slideY(begin: -1.0, end: 0.0, duration: 600.ms);
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;

    switch (_rideStatus) {
      case 'booked':
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'arriving':
        statusColor = Colors.orange;
        statusIcon = Icons.directions_car;
        break;
      case 'arrived':
        statusColor = Colors.blue;
        statusIcon = Icons.location_on;
        break;
      case 'in_transit':
        statusColor = Colors.purple;
        statusIcon = Icons.navigation;
        break;
      case 'completed':
        statusColor = AppColors.accentGreen;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = AppColors.gray400;
        statusIcon = Icons.info;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                statusColor.withOpacity(0.1 + (_pulseController.value * 0.1)),
            shape: BoxShape.circle,
            border: Border.all(
              color: statusColor,
              width: 2,
            ),
          ),
          child: Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _userLocation ?? const LatLng(19.0760, 72.8777),
          zoom: 15.0,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        buildingsEnabled: true,
        trafficEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        scrollGesturesEnabled: true,
        zoomGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: false,
      ),
    );
  }

  Widget _buildRideInfo() {
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
            _buildRiderCard(),
            _buildTripDetails(),
            _buildActionButtons(),
            const SizedBox(height: 24),
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
    );
  }

  Widget _buildRiderCard() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
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
                Text(
                  '${widget.rider.vehicleNumber} • ${widget.rider.vehicleMake}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.rider.rating}',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                // TODO: Implement call functionality
                HapticFeedback.lightImpact();
              },
              icon: const Icon(
                Icons.call,
                color: AppColors.accentGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Details',
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${AppConstants.currencySymbol}${(widget.rider.farePerPassenger * (widget.rideData['passenger_count'] ?? 1)).toInt()}',
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Distance: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              Text(
                '${widget.rider.distanceKm} km',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 24),
              Text(
                'Passengers: ',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              Text(
                '${widget.rideData['passenger_count'] ?? 1}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          if (_rideStatus == 'booked' || _rideStatus == 'arriving') ...[
            CustomButton(
              onPressed: _cancelRide,
              text: 'Cancel Ride',
              style: CustomButtonStyle.danger,
              icon: Icons.close_rounded,
            ),
          ] else if (_rideStatus == 'completed') ...[
            CustomButton(
              onPressed: () {
                // TODO: Navigate to rating page
                Navigator.pushReplacementNamed(context, '/home');
              },
              text: 'Rate Your Ride',
              style: CustomButtonStyle.primary,
              icon: Icons.star_rounded,
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusTitle() {
    switch (_rideStatus) {
      case 'booked':
        return 'Ride Confirmed';
      case 'arriving':
        return 'Driver Arriving';
      case 'arrived':
        return 'Driver Has Arrived';
      case 'in_transit':
        return 'Trip in Progress';
      case 'completed':
        return 'Trip Completed';
      default:
        return 'Ride Status';
    }
  }

  String _getStatusSubtitle() {
    switch (_rideStatus) {
      case 'booked':
        return 'Your driver is on the way';
      case 'arriving':
        return 'ETA: ${widget.rider.etaMinutes} minutes';
      case 'arrived':
        return 'Your driver is waiting for you';
      case 'in_transit':
        return 'Enjoy your ride!';
      case 'completed':
        return 'Thank you for using AutoWala';
      default:
        return 'Tracking your ride...';
    }
  }
}
