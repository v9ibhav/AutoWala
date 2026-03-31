import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class RideHistoryPage extends ConsumerStatefulWidget {
  const RideHistoryPage({super.key});

  @override
  ConsumerState<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends ConsumerState<RideHistoryPage> {
  bool _isLoading = true;
  List<RideHistoryItem> _rides = [];

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to fetch ride history
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Mock data for now
      _rides = [
        RideHistoryItem(
          id: 'ride_001',
          date: DateTime.now().subtract(const Duration(days: 1)),
          pickupAddress: 'Home - Bandra West',
          destinationAddress: 'Office - Andheri East',
          fare: 85.00,
          distance: 4.2,
          duration: 18,
          driverName: 'Ravi Kumar',
          rating: 5,
          status: 'completed',
        ),
        RideHistoryItem(
          id: 'ride_002',
          date: DateTime.now().subtract(const Duration(days: 3)),
          pickupAddress: 'Mall - Phoenix Mills',
          destinationAddress: 'Restaurant - Linking Road',
          fare: 45.00,
          distance: 2.1,
          duration: 12,
          driverName: 'Suresh Singh',
          rating: 4,
          status: 'completed',
        ),
        RideHistoryItem(
          id: 'ride_003',
          date: DateTime.now().subtract(const Duration(days: 5)),
          pickupAddress: 'Station - Bandra',
          destinationAddress: 'Home - Bandra West',
          fare: 30.00,
          distance: 1.5,
          duration: 8,
          driverName: 'Amit Sharma',
          rating: 5,
          status: 'completed',
        ),
      ];
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load ride history'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        title: const Text('Ride History'),
        backgroundColor: AppColors.primaryWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
              ),
            )
          : _rides.isEmpty
              ? _buildEmptyState()
              : _buildRideList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.gray300.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history,
                size: 40,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Rides Yet',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed rides will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList() {
    return RefreshIndicator(
      onRefresh: _loadRideHistory,
      color: AppColors.accentGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          return _buildRideItem(_rides[index]);
        },
      ),
    );
  }

  Widget _buildRideItem(RideHistoryItem ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        borderRadius: AppBorders.medium,
        boxShadow: AppShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(ride.date),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(ride.status).withOpacity(0.1),
                  borderRadius: AppBorders.small,
                ),
                child: Text(
                  ride.status.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _getStatusColor(ride.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Route information
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.pickupAddress,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(left: 4),
                height: 20,
                width: 1,
                color: AppColors.gray300,
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ride.destinationAddress,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trip details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Fare',
                  '₹${ride.fare.toStringAsFixed(0)}',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Distance',
                  '${ride.distance.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Duration',
                  '${ride.duration} min',
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Driver info and rating
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver: ${ride.driverName}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              Row(
                children: [
                  ...List.generate(
                    ride.rating,
                    (index) => const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.warning,
                    ),
                  ),
                  ...List.generate(
                    5 - ride.rating,
                    (index) => const Icon(
                      Icons.star_border,
                      size: 16,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'in_progress':
        return AppColors.warning;
      default:
        return AppColors.gray500;
    }
  }
}

class RideHistoryItem {
  final String id;
  final DateTime date;
  final String pickupAddress;
  final String destinationAddress;
  final double fare;
  final double distance;
  final int duration;
  final String driverName;
  final int rating;
  final String status;

  RideHistoryItem({
    required this.id,
    required this.date,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.fare,
    required this.distance,
    required this.duration,
    required this.driverName,
    required this.rating,
    required this.status,
  });
}