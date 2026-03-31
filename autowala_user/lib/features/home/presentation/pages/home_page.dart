import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../ride/data/models/rider_data.dart';
import '../widgets/nearby_autos_bottom_sheet.dart';
import '../widgets/location_search_widget.dart';
import '../widgets/map_controls_widget.dart';

/// Main home page with map-first interface
/// Core ride discovery experience for users
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with TickerProviderStateMixin {
  // Map Controller
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controller = Completer();

  // Location & State
  Position? _currentPosition;
  LatLng _currentLocation = const LatLng(
    AppConstants.defaultLatitude,
    AppConstants.defaultLongitude,
  );

  // UI State
  bool _isLoadingLocation = true;
  bool _isSearchingRiders = false;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Animation Controllers
  late AnimationController _fabAnimationController;
  late AnimationController _bottomSheetAnimationController;

  // Search State
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String? _pickupAddress;
  String? _dropoffAddress;
  List<RiderData> _nearbyRiders = []; // Store nearby riders data

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeLocation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _bottomSheetAnimationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: AppConstants.animationDuration,
      vsync: this,
    );

    _bottomSheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  Future<void> _initializeLocation() async {
    final performanceLogger = PerformanceLogger('location_initialization');

    try {
      // Check permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceDialog();
        performanceLogger.stop('service_disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        _showLocationPermissionDialog();
        performanceLogger.stop('permission_denied');
        return;
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _currentLocation = LatLng(position.latitude, position.longitude);
        _pickupLocation = _currentLocation;
        _isLoadingLocation = false;
      });

      // Move camera to user location
      _moveCameraToLocation(_currentLocation);

      // Start location updates
      _startLocationUpdates();

      // Search for nearby riders
      _searchNearbyRiders();

      _fabAnimationController.forward();
      performanceLogger.stop('completed');

      AppLogger.location('location_initialized',
          latitude: position.latitude, longitude: position.longitude);
    } catch (error, stackTrace) {
      setState(() {
        _isLoadingLocation = false;
      });

      performanceLogger.stop('failed');
      AppLogger.error('Failed to initialize location', error, stackTrace);
      _showLocationErrorDialog();
    }
  }

  void _startLocationUpdates() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // Send location update to backend API
          _sendLocationUpdateToBackend(position);

          AppLogger.debug('Location updated', {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
          });
        }
      },
      onError: (error) {
        AppLogger.error('Location stream error', error);
      },
    );
  }

  Future<void> _sendLocationUpdateToBackend(Position position) async {
    try {
      final apiService = ref.read(apiServiceProvider);

      await apiService.post('/user/location-update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().toIso8601String(),
      });

      AppLogger.debug('Location sent to backend successfully');
    } catch (error, stackTrace) {
      AppLogger.error('Failed to send location update to backend', error, stackTrace);
      // Don't show error to user as this runs frequently in background
    }
  }

  Future<void> _moveCameraToLocation(LatLng location) async {
    final controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(location, AppConstants.defaultLocationZoom),
    );
  }

  Future<void> _searchNearbyRiders() async {
    if (_currentLocation == null) return;

    setState(() {
      _isSearchingRiders = true;
    });

    try {
      // Call API to search nearby riders
      final apiService = ref.read(apiServiceProvider);

      final response = await apiService.post('/rides/search-nearby', {
        'latitude': _currentLocation.latitude,
        'longitude': _currentLocation.longitude,
        'radius_km': AppConstants.searchRadiusKm,
        'max_results': 20,
      });

      if (response['success'] == true && response['data'] != null) {
        final ridersData = response['data']['riders'] as List<dynamic>? ?? [];

        // Convert API response to RiderData objects
        final riders = ridersData
            .map((riderJson) => RiderData.fromJson(riderJson))
            .toList();

        // Store riders data for later use
        setState(() {
          _nearbyRiders = riders;
        });

        // Add rider markers to map
        _addRiderMarkersToMap(riders);

        AppLogger.userAction('nearby_riders_found', parameters: {
          'location': [_currentLocation.latitude, _currentLocation.longitude],
          'riders_count': riders.length,
          'radius_km': AppConstants.searchRadiusKm,
        });
      } else {
        // Fallback to mock data if API returns empty or error
        _addMockRiderMarkers();
        AppLogger.warning('API returned no riders, using mock data');
      }

      _bottomSheetAnimationController.forward();

      AppLogger.ride('nearby_search_completed', data: {
        'location': [_currentLocation.latitude, _currentLocation.longitude],
        'radius_km': AppConstants.searchRadiusKm,
      });
    } catch (error, stackTrace) {
      AppLogger.error('Failed to search nearby riders', error, stackTrace);
      _showErrorSnackBar('Failed to find nearby auto-rickshaws');
    } finally {
      setState(() {
        _isSearchingRiders = false;
      });
    }
  }

  void _addRiderMarkersToMap(List<RiderData> riders) {
    final markers = <Marker>{};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add rider markers with real data
    for (int i = 0; i < riders.length; i++) {
      final rider = riders[i];
      final riderLocation = LatLng(
        rider.currentLatitude ?? _currentLocation.latitude,
        rider.currentLongitude ?? _currentLocation.longitude,
      );

      markers.add(
        Marker(
          markerId: MarkerId('rider_${rider.id}'),
          position: riderLocation,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: rider.fullName,
            snippet:
                '${rider.vehicleType ?? 'Auto-Rickshaw'} • ⭐${rider.rating?.toStringAsFixed(1) ?? '4.5'} • ₹${rider.baseFare?.toInt() ?? 30}',
          ),
          onTap: () => _onRiderMarkerTapped(i, rider),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });

    AppLogger.debug('Added ${riders.length} rider markers to map');
  }

  void _addMockRiderMarkers() {
    // Fallback method for when API returns no data
    final mockRiders = [
      LatLng(_currentLocation.latitude + 0.001,
          _currentLocation.longitude + 0.001),
      LatLng(_currentLocation.latitude - 0.002,
          _currentLocation.longitude + 0.0015),
      LatLng(_currentLocation.latitude + 0.0015,
          _currentLocation.longitude - 0.001),
    ];

    final markers = <Marker>{};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add mock rider markers
    for (int i = 0; i < mockRiders.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('mock_rider_$i'),
          position: mockRiders[i],
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Rider ${i + 1}',
            snippet: 'Auto-Rickshaw • ₹30/passenger',
          ),
          onTap: () => _onMockRiderMarkerTapped(i),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  void _onRiderMarkerTapped(int riderIndex, RiderData rider) {
    HapticFeedback.lightImpact();
    AppLogger.userAction('rider_marker_tapped',
        parameters: {'rider_id': rider.id, 'rider_name': rider.fullName});

    // Show rider details in bottom sheet with real data
    _showRealRiderBottomSheet(rider);
  }

  void _onMockRiderMarkerTapped(int riderIndex) {
    HapticFeedback.lightImpact();
    AppLogger.userAction('mock_rider_marker_tapped',
        parameters: {'rider_index': riderIndex});

    // Show rider details in bottom sheet with mock data
    _showMockRiderBottomSheet(riderIndex);
  }

  void _showRealRiderBottomSheet(RiderData rider) {
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Rider info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gray200,
                  child: rider.profilePicture != null && rider.profilePicture!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            rider.profilePicture!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'R',
                              style: AppTextStyles.labelLarge,
                            ),
                          ),
                        )
                      : Text(
                          rider.fullName.isNotEmpty ? rider.fullName[0].toUpperCase() : 'R',
                          style: AppTextStyles.labelLarge,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.fullName,
                        style: AppTextStyles.h4,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${rider.rating?.toStringAsFixed(1) ?? '4.5'} (${rider.totalRides ?? 0} trips)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${rider.baseFare?.toInt() ?? 30}',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Vehicle info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColors.gray600,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.vehiclePlateNumber ?? 'MH 01 AB 1234',
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        '${rider.vehicleBrand ?? 'Bajaj'} ${rider.vehicleType ?? 'Auto Rickshaw'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${rider.distanceKm?.toStringAsFixed(1) ?? '0.5'} km away',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callRealRider(rider),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _bookRealRider(rider),
                    icon: const Icon(Icons.check),
                    label: const Text('Book This Auto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMockRiderBottomSheet(int riderIndex) {
    showBarModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.primaryWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Rider info
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.gray200,
                  child: Text(
                    'R${riderIndex + 1}',
                    style: AppTextStyles.labelLarge,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rider ${riderIndex + 1}',
                        style: AppTextStyles.h4,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8 (156 trips)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹30',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.accentGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Vehicle info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColors.gray600,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MH 01 AB 1234',
                        style: AppTextStyles.labelLarge,
                      ),
                      Text(
                        'Yellow Bajaj Auto',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '2 min away',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callRider(riderIndex),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _bookRider(riderIndex),
                    icon: const Icon(Icons.check),
                    label: const Text('Book This Auto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _callRealRider(RiderData rider) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    AppLogger.userAction('call_real_rider', parameters: {
      'rider_id': rider.id,
      'rider_name': rider.fullName,
      'rider_phone': rider.phoneNumber
    });

    _showSnackBar('Calling ${rider.fullName}...', icon: Icons.phone);

    // Implement phone call functionality
    try {
      final phoneNumber = rider.phoneNumber;
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
          AppLogger.userAction('phone_call_initiated', parameters: {
            'rider_id': rider.id,
            'rider_name': rider.fullName,
          });
        } else {
          throw Exception('Cannot launch phone app');
        }
      } else {
        throw Exception('Phone number not available');
      }
    } catch (error) {
      AppLogger.error('Failed to make phone call', error);
      _showErrorSnackBar('Unable to make phone call. Please try again.');
    }
  }

  void _bookRealRider(RiderData rider) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    AppLogger.userAction('book_real_rider', parameters: {
      'rider_id': rider.id,
      'rider_name': rider.fullName,
      'fare': rider.baseFare
    });

    // Navigate to ride booking page with real rider data
    context.goToRideBooking(
      pickupLocation: {
        'latitude': _currentLocation.latitude,
        'longitude': _currentLocation.longitude,
        'address': _pickupAddress ?? 'Current Location',
      },
      riderId: rider.id,
      riderName: rider.fullName,
      baseFare: rider.baseFare,
    );
  }

  void _callRider(int riderIndex) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    AppLogger.userAction('call_rider', parameters: {'rider_index': riderIndex});

    _showSnackBar('Calling rider...', icon: Icons.phone);
  }

  void _bookRider(int riderIndex) {
    Navigator.pop(context);
    HapticFeedback.mediumImpact();
    AppLogger.userAction('book_rider', parameters: {'rider_index': riderIndex});

    // Navigate to ride booking page
    context.goToRideBooking(
      pickupLocation: {
        'latitude': _currentLocation.latitude,
        'longitude': _currentLocation.longitude,
        'address': _pickupAddress ?? 'Current Location',
      },
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Required'),
        content: const Text(
          'Please enable location services to find nearby auto-rickshaws.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'AutoWala needs location access to find nearby auto-rickshaws and provide ride services.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: const Text(
          'Unable to get your current location. Please check your location settings and try again.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeLocation();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.primaryWhite, size: 20),
              const SizedBox(width: 12),
            ],
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primaryBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showSnackBar(message, icon: Icons.error_outline);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Map
          _buildMap(),

          // Top UI Controls
          _buildTopControls(),

          // Floating Action Buttons
          _buildFloatingActionButtons(),

          // Loading Overlay
          if (_isLoadingLocation) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: AppConstants.defaultZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      myLocationEnabled: false, // Custom location marker
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onTap: (LatLng position) {
        // Hide any open bottom sheets
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      style: AppConstants.mapStyleDay,
    );
  }

  Widget _buildTopControls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar for destination
            LocationSearchWidget(
              onLocationSelected: (location, address) {
                setState(() {
                  _dropoffLocation = location;
                  _dropoffAddress = address;
                });
                _searchNearbyRiders();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Column(
        children: [
          // Current Location Button
          FloatingActionButton(
            heroTag: 'current_location',
            mini: true,
            backgroundColor: AppColors.primaryWhite,
            foregroundColor: AppColors.primaryBlack,
            onPressed: () {
              HapticFeedback.lightImpact();
              _moveCameraToLocation(_currentLocation);
            },
            child: const Icon(Icons.my_location),
          )
              .animate(controller: _fabAnimationController)
              .scale(duration: 300.ms)
              .fadeIn(),

          const SizedBox(height: 12),

          // Menu Button
          FloatingActionButton(
            heroTag: 'menu',
            mini: true,
            backgroundColor: AppColors.primaryBlack,
            foregroundColor: AppColors.primaryWhite,
            onPressed: () {
              HapticFeedback.lightImpact();
              context.goToProfile();
            },
            child: const Icon(Icons.person),
          )
              .animate(controller: _fabAnimationController)
              .scale(delay: 100.ms, duration: 300.ms)
              .fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: AppColors.primaryWhite.withOpacity(0.9),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
