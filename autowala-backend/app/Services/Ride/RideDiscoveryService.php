<?php

namespace App\Services\Ride;

use App\Models\Rider;
use App\Models\Ride;
use App\Models\Rating;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class RideDiscoveryService
{
    /**
     * Base fare and pricing configuration
     */
    private const BASE_FARE = 30; // Rs. 30 base fare
    private const RATE_PER_KM = 12; // Rs. 12 per km
    private const MIN_FARE = 50; // Rs. 50 minimum fare
    private const MAX_FARE = 500; // Rs. 500 maximum fare for safety
    private const SURGE_MULTIPLIER = 1.5; // During peak hours

    /**
     * Find nearby available riders using PostGIS spatial queries
     */
    public function findNearbyRiders(array $userLocation, int $radius = 5000, array $destination = null): array
    {
        try {
            $latitude = $userLocation['latitude'];
            $longitude = $userLocation['longitude'];

            // Use PostGIS to find riders within specified radius
            $query = Rider::select([
                'riders.*',
                'vehicles.registration_number',
                'vehicles.model',
                'vehicles.color',
                'vehicles.capacity'
            ])
            ->selectRaw('
                ST_Distance(
                    ST_GeogFromText(\'POINT(' . $longitude . ' ' . $latitude . ')\'),
                    ST_GeogFromText(CONCAT(\'POINT(\', current_longitude, \' \', current_latitude, \')\'))
                ) as distance_meters
            ')
            ->selectRaw('
                ST_Azimuth(
                    ST_GeogFromText(\'POINT(' . $longitude . ' ' . $latitude . ')\'),
                    ST_GeogFromText(CONCAT(\'POINT(\', current_longitude, \' \', current_latitude, \')\'))
                ) * 180 / PI() as bearing
            ')
            ->join('vehicles', 'riders.id', '=', 'vehicles.rider_id')
            ->where('riders.is_online', true)
            ->where('riders.accepts_rides', true)
            ->where('riders.kyc_verified', true)
            ->whereRaw('
                ST_DWithin(
                    ST_GeogFromText(\'POINT(' . $longitude . ' ' . $latitude . ')\'),
                    ST_GeogFromText(CONCAT(\'POINT(\', riders.current_longitude, \' \', riders.current_latitude, \')\'))
                    , ?
                )
            ', [$radius])
            ->orderByRaw('distance_meters ASC')
            ->limit(15); // Limit to 15 nearest riders

            $nearbyRiders = $query->get();

            // Transform the results
            return $nearbyRiders->map(function ($rider) use ($userLocation, $destination) {
                $eta = $this->calculateETA(
                    [$rider->current_latitude, $rider->current_longitude],
                    $userLocation
                );

                return [
                    'id' => $rider->id,
                    'name' => $rider->name,
                    'phone' => substr($rider->phone, 0, -2) . 'XX', // Mask last 2 digits
                    'rating' => $this->getCachedRiderRating($rider->id),
                    'total_rides' => $rider->total_rides,
                    'vehicle' => [
                        'registration_number' => $rider->registration_number,
                        'model' => $rider->model,
                        'color' => $rider->color,
                        'capacity' => $rider->capacity,
                    ],
                    'location' => [
                        'latitude' => $rider->current_latitude,
                        'longitude' => $rider->current_longitude,
                        'distance_meters' => round($rider->distance_meters),
                        'bearing' => $rider->bearing ? round($rider->bearing, 2) : null,
                        'last_updated' => $rider->last_location_update,
                    ],
                    'availability' => [
                        'eta_minutes' => $eta,
                        'accepts_cash' => true,
                        'accepts_digital' => $rider->accepts_digital_payment,
                    ],
                    'route_compatibility' => $destination ?
                        $this->checkRouteCompatibility($rider->id, $userLocation, $destination) : null
                ];
            })->toArray();

        } catch (\Exception $e) {
            Log::error('Failed to find nearby riders', [
                'location' => $userLocation,
                'radius' => $radius,
                'error' => $e->getMessage()
            ]);

            return [];
        }
    }

    /**
     * Calculate fare for a trip based on distance and current demand
     */
    public function calculateFare(array $pickup, array $destination): array
    {
        try {
            // Calculate distance using PostGIS
            $distanceQuery = DB::selectOne('
                SELECT ST_Distance(
                    ST_GeogFromText(\'POINT(' . $pickup[1] . ' ' . $pickup[0] . ')\'),
                    ST_GeogFromText(\'POINT(' . $destination[1] . ' ' . $destination[0] . ')\')
                ) as distance_meters
            ');

            $distanceKm = $distanceQuery->distance_meters / 1000;

            // Base fare calculation
            $baseFare = self::BASE_FARE;
            $distanceFare = $distanceKm * self::RATE_PER_KM;
            $subtotal = $baseFare + $distanceFare;

            // Apply surge pricing during peak hours (if needed)
            $surgeMultiplier = $this->getSurgeMultiplier();
            $surgeAmount = $subtotal * ($surgeMultiplier - 1);

            // Calculate total
            $total = $subtotal + $surgeAmount;

            // Apply min/max fare limits
            $total = max(self::MIN_FARE, min(self::MAX_FARE, $total));

            return [
                'base_fare' => round($baseFare, 2),
                'distance_km' => round($distanceKm, 2),
                'distance_fare' => round($distanceFare, 2),
                'subtotal' => round($subtotal, 2),
                'surge_multiplier' => $surgeMultiplier,
                'surge_amount' => round($surgeAmount, 2),
                'total' => round($total, 2),
                'currency' => 'INR',
                'breakdown' => [
                    "Base fare: ₹{$baseFare}",
                    "Distance ({$distanceKm}km @ ₹" . self::RATE_PER_KM . "/km): ₹{$distanceFare}",
                    $surgeMultiplier > 1 ? "Surge ({$surgeMultiplier}x): ₹{$surgeAmount}" : null,
                    "Total: ₹{$total}"
                ]
            ];

        } catch (\Exception $e) {
            Log::error('Fare calculation failed', [
                'pickup' => $pickup,
                'destination' => $destination,
                'error' => $e->getMessage()
            ]);

            // Return default fare on error
            return [
                'base_fare' => self::BASE_FARE,
                'distance_km' => 0,
                'distance_fare' => 0,
                'subtotal' => self::MIN_FARE,
                'surge_multiplier' => 1.0,
                'surge_amount' => 0,
                'total' => self::MIN_FARE,
                'currency' => 'INR',
                'error' => 'Could not calculate exact fare'
            ];
        }
    }

    /**
     * Calculate estimated time of arrival (ETA) in minutes
     */
    public function calculateETA(array $fromLocation, array $toLocation): int
    {
        try {
            // Calculate distance
            $distanceQuery = DB::selectOne('
                SELECT ST_Distance(
                    ST_GeogFromText(\'POINT(' . $fromLocation[1] . ' ' . $fromLocation[0] . ')\'),
                    ST_GeogFromText(\'POINT(' . $toLocation[1] . ' ' . $toLocation[0] . ')\')
                ) as distance_meters
            ');

            $distanceKm = $distanceQuery->distance_meters / 1000;

            // Average speed in Indian urban areas (considering traffic)
            $avgSpeedKmh = $this->getAverageSpeedForTime();

            // Calculate ETA in minutes
            $etaHours = $distanceKm / $avgSpeedKmh;
            $etaMinutes = $etaHours * 60;

            // Add buffer time for pickup/preparation (2-5 minutes)
            $bufferMinutes = min(5, max(2, $distanceKm * 0.5));

            $totalETA = ceil($etaMinutes + $bufferMinutes);

            // Reasonable bounds
            return max(2, min(60, $totalETA)); // 2 min to 1 hour max

        } catch (\Exception $e) {
            Log::error('ETA calculation failed', [
                'from' => $fromLocation,
                'to' => $toLocation,
                'error' => $e->getMessage()
            ]);

            return 10; // Default 10 minutes on error
        }
    }

    /**
     * Match user with best available rider based on multiple factors
     */
    public function matchUserWithRider(int $userId, int $riderId): bool
    {
        try {
            // Check if rider is still available
            $rider = Rider::where('id', $riderId)
                ->where('is_online', true)
                ->where('accepts_rides', true)
                ->first();

            if (!$rider) {
                return false;
            }

            // Check if rider doesn't have conflicting bookings
            $conflictingRides = Ride::where('rider_id', $riderId)
                ->whereIn('status', ['pending', 'accepted', 'in_transit'])
                ->count();

            if ($conflictingRides > 0) {
                return false;
            }

            return true;

        } catch (\Exception $e) {
            Log::error('Rider matching failed', [
                'user_id' => $userId,
                'rider_id' => $riderId,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Update ride status with proper validations
     */
    public function updateRideStatus(string $rideId, string $status): bool
    {
        try {
            $validStatuses = ['pending', 'accepted', 'in_transit', 'completed', 'cancelled'];

            if (!in_array($status, $validStatuses)) {
                return false;
            }

            $ride = Ride::find($rideId);
            if (!$ride) {
                return false;
            }

            // Status transition validations
            $allowedTransitions = [
                'pending' => ['accepted', 'cancelled'],
                'accepted' => ['in_transit', 'cancelled'],
                'in_transit' => ['completed', 'cancelled'],
                'completed' => [], // Final state
                'cancelled' => []  // Final state
            ];

            if (!in_array($status, $allowedTransitions[$ride->status] ?? [])) {
                return false;
            }

            // Update with timestamp
            $updateData = ['status' => $status];

            switch ($status) {
                case 'accepted':
                    $updateData['accepted_at'] = now();
                    break;
                case 'in_transit':
                    $updateData['started_at'] = now();
                    break;
                case 'completed':
                    $updateData['completed_at'] = now();
                    $updateData['final_fare'] = $ride->estimated_fare; // Could be calculated based on actual route
                    break;
                case 'cancelled':
                    $updateData['cancelled_at'] = now();
                    break;
            }

            $ride->update($updateData);

            return true;

        } catch (\Exception $e) {
            Log::error('Failed to update ride status', [
                'ride_id' => $rideId,
                'status' => $status,
                'error' => $e->getMessage()
            ]);

            return false;
        }
    }

    /**
     * Update rider's overall rating after receiving new rating
     */
    public function updateRiderRating(int $riderId): void
    {
        try {
            $riderRatings = Ride::where('rider_id', $riderId)
                ->whereNotNull('user_rating')
                ->selectRaw('AVG(user_rating) as avg_rating, COUNT(*) as total_ratings')
                ->first();

            if ($riderRatings) {
                Rider::where('id', $riderId)->update([
                    'overall_rating' => round($riderRatings->avg_rating, 2),
                    'rating_count' => $riderRatings->total_ratings
                ]);

                // Clear cached rating
                Cache::forget("rider_rating_{$riderId}");
            }

        } catch (\Exception $e) {
            Log::error('Failed to update rider rating', [
                'rider_id' => $riderId,
                'error' => $e->getMessage()
            ]);
        }
    }

    /**
     * Get cached rider rating for performance
     */
    private function getCachedRiderRating(int $riderId): float
    {
        return Cache::remember("rider_rating_{$riderId}", 300, function () use ($riderId) {
            $rider = Rider::find($riderId);
            return $rider ? round($rider->overall_rating ?? 4.0, 1) : 4.0;
        });
    }

    /**
     * Get current surge multiplier based on demand and time
     */
    private function getSurgeMultiplier(): float
    {
        $currentHour = now()->hour;

        // Peak hours: 8-10 AM and 6-8 PM
        if (($currentHour >= 8 && $currentHour <= 10) || ($currentHour >= 18 && $currentHour <= 20)) {
            return self::SURGE_MULTIPLIER;
        }

        return 1.0;
    }

    /**
     * Get average speed based on current time (traffic conditions)
     */
    private function getAverageSpeedForTime(): float
    {
        $currentHour = now()->hour;

        // Speed in km/h based on traffic conditions
        if ($currentHour >= 7 && $currentHour <= 10) {
            return 15; // Morning rush hour
        } elseif ($currentHour >= 17 && $currentHour <= 20) {
            return 12; // Evening rush hour
        } elseif ($currentHour >= 23 || $currentHour <= 5) {
            return 35; // Night time
        } else {
            return 25; // Regular hours
        }
    }

    /**
     * Check if rider's route is compatible with user's destination
     */
    private function checkRouteCompatibility(int $riderId, array $pickup, array $destination): ?array
    {
        try {
            // This would implement route optimization logic
            // For now, return basic compatibility
            return [
                'compatible' => true,
                'detour_distance' => 0,
                'efficiency_score' => 0.9
            ];

        } catch (\Exception $e) {
            return null;
        }
    }
}