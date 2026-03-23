<?php

namespace App\Http\Controllers\Api\User;

use App\Http\Controllers\Controller;
use App\Services\Location\GeospatialService;
use App\Services\Location\DistanceCalculator;
use App\Services\Firebase\RealtimeService;
use App\Models\Rider;
use App\Models\RideLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class RideController extends Controller
{
    protected GeospatialService $geospatialService;
    protected DistanceCalculator $distanceCalculator;
    protected RealtimeService $realtimeService;

    public function __construct(
        GeospatialService $geospatialService,
        DistanceCalculator $distanceCalculator,
        RealtimeService $realtimeService
    ) {
        $this->geospatialService = $geospatialService;
        $this->distanceCalculator = $distanceCalculator;
        $this->realtimeService = $realtimeService;
    }

    /**
     * Search for nearby auto-rickshaws
     */
    public function searchNearby(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pickup_latitude' => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'dropoff_latitude' => 'nullable|numeric|between:-90,90',
            'dropoff_longitude' => 'nullable|numeric|between:-180,180',
            'radius_km' => 'nullable|numeric|min:0.5|max:25',
            'passengers' => 'nullable|integer|min:1|max:3',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid location parameters',
                'errors' => $validator->errors(),
            ], 422);
        }

        $pickupLat = $request->pickup_latitude;
        $pickupLon = $request->pickup_longitude;
        $dropoffLat = $request->dropoff_latitude;
        $dropoffLon = $request->dropoff_longitude;
        $radiusKm = $request->radius_km ?? 5;
        $passengers = $request->passengers ?? 1;

        try {
            // Validate coordinates are in India
            if (!$this->geospatialService->isLocationInIndia($pickupLat, $pickupLon)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Pickup location must be within India',
                ], 422);
            }

            if ($dropoffLat && $dropoffLon &&
                !$this->geospatialService->isLocationInIndia($dropoffLat, $dropoffLon)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Dropoff location must be within India',
                ], 422);
            }

            // Find nearby riders using PostGIS
            $nearbyRiders = $this->geospatialService->findNearbyRiders(
                $pickupLat,
                $pickupLon,
                $radiusKm,
                20 // Limit to 20 riders
            );

            // If dropoff is provided, also find riders on route
            $routeRiders = collect([]);
            if ($dropoffLat && $dropoffLon) {
                $routeRiders = $this->geospatialService->findRidersOnRoute(
                    $pickupLat,
                    $pickupLon,
                    $dropoffLat,
                    $dropoffLon,
                    2, // 2km buffer
                    15 // Limit to 15 riders
                );
            }

            // Get real-time location data from Firebase
            $firebaseRiders = $this->realtimeService->getActiveRidersInArea(
                $pickupLat,
                $pickupLon,
                $radiusKm
            );

            // Merge and enhance rider data
            $enrichedRiders = $this->enrichRiderData(
                $nearbyRiders,
                $routeRiders,
                $firebaseRiders,
                $pickupLat,
                $pickupLon,
                $dropoffLat,
                $dropoffLon,
                $passengers
            );

            // Calculate area information
            $areaInfo = [
                'pickup_area' => $this->distanceCalculator->getApproximateArea($pickupLat, $pickupLon),
                'total_riders_found' => count($enrichedRiders),
                'search_radius_km' => $radiusKm,
                'has_dropoff' => !is_null($dropoffLat) && !is_null($dropoffLon),
            ];

            Log::info('Nearby riders search completed', [
                'user_id' => $request->user()->id,
                'pickup' => [$pickupLat, $pickupLon],
                'dropoff' => $dropoffLat ? [$dropoffLat, $dropoffLon] : null,
                'riders_found' => count($enrichedRiders),
                'radius_km' => $radiusKm
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Nearby auto-rickshaws found',
                'data' => [
                    'riders' => $enrichedRiders,
                    'area_info' => $areaInfo,
                    'search_params' => [
                        'pickup' => ['latitude' => $pickupLat, 'longitude' => $pickupLon],
                        'dropoff' => $dropoffLat ? ['latitude' => $dropoffLat, 'longitude' => $dropoffLon] : null,
                        'radius_km' => $radiusKm,
                        'passengers' => $passengers,
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to search nearby riders', [
                'user_id' => $request->user()->id,
                'pickup' => [$pickupLat, $pickupLon],
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to search for nearby auto-rickshaws',
            ], 500);
        }
    }

    /**
     * Get specific rider details
     */
    public function riderDetails(Request $request, int $riderId): JsonResponse
    {
        try {
            $rider = Rider::with(['user', 'vehicle', 'activeRoutes.routePoints'])
                ->where('id', $riderId)
                ->where('is_online', true)
                ->where('is_active', true)
                ->where('kyc_status', 'verified')
                ->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Auto-rickshaw not found or not available',
                ], 404);
            }

            // Get real-time location from Firebase
            $firebaseData = $this->realtimeService->getRideSession($riderId);

            // Calculate distance and ETA if user's location is provided
            $userLat = $request->query('user_latitude');
            $userLon = $request->query('user_longitude');

            $distanceInfo = null;
            if ($userLat && $userLon && $rider->current_location) {
                $currentLocation = $rider->current_location;
                $distance = $this->distanceCalculator->haversineDistance(
                    $userLat,
                    $userLon,
                    $currentLocation['latitude'],
                    $currentLocation['longitude']
                );

                $travelTime = $this->distanceCalculator->calculateTravelTime($distance);
                $distanceInfo = $travelTime;
            }

            $riderData = [
                'id' => $rider->id,
                'full_name' => $rider->full_name,
                'phone_number' => $rider->phone_number,
                'average_rating' => $rider->average_rating,
                'total_rides' => $rider->total_rides,
                'fare_per_passenger' => $rider->fare_per_passenger,
                'is_online' => $rider->is_online,
                'location_updated_at' => $rider->location_updated_at,
                'current_location' => $rider->current_location,
                'distance_info' => $distanceInfo,
                'vehicle' => [
                    'id' => $rider->vehicle->id,
                    'registration_number' => $rider->vehicle->registration_number,
                    'make' => $rider->vehicle->make,
                    'model' => $rider->vehicle->model,
                    'color' => $rider->vehicle->color,
                    'max_passengers' => $rider->vehicle->max_passengers,
                    'display_name' => $rider->vehicle->display_name,
                ],
                'active_routes' => $rider->activeRoutes->map(function ($route) {
                    return [
                        'id' => $route->id,
                        'route_name' => $route->route_name,
                        'description' => $route->description,
                        'total_distance_km' => $route->total_distance_km,
                        'estimated_duration_min' => $route->estimated_duration_min,
                        'route_points' => $route->routePoints->map(function ($point) {
                            return [
                                'location_name' => $point->location_name,
                                'coordinates' => $point->coordinates,
                                'sequence_order' => $point->sequence_order,
                                'estimated_arrival_min' => $point->estimated_arrival_min,
                            ];
                        }),
                    ];
                }),
                'firebase_data' => $firebaseData,
            ];

            return response()->json([
                'status' => 'success',
                'message' => 'Auto-rickshaw details retrieved',
                'data' => ['rider' => $riderData],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get rider details', [
                'rider_id' => $riderId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to retrieve auto-rickshaw details',
            ], 500);
        }
    }

    /**
     * Book an auto-rickshaw
     */
    public function bookRide(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'rider_id' => 'required|integer|exists:riders,id',
            'pickup_latitude' => 'required|numeric|between:-90,90',
            'pickup_longitude' => 'required|numeric|between:-180,180',
            'pickup_address' => 'required|string|max:500',
            'dropoff_latitude' => 'nullable|numeric|between:-90,90',
            'dropoff_longitude' => 'nullable|numeric|between:-180,180',
            'dropoff_address' => 'nullable|string|max:500',
            'passengers' => 'required|integer|min:1|max:3',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid booking parameters',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        try {
            // Check if user already has an active ride
            if ($user->hasActiveRide()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'You already have an active ride',
                    'data' => ['active_ride' => $user->activeRide()],
                ], 409);
            }

            $riderId = $request->rider_id;
            $rider = Rider::with('vehicle')->find($riderId);

            if (!$rider || !$rider->is_online || !$rider->is_active || $rider->kyc_status !== 'verified') {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Selected auto-rickshaw is not available',
                ], 409);
            }

            // Calculate distance and fare estimate
            $pickupLat = $request->pickup_latitude;
            $pickupLon = $request->pickup_longitude;
            $dropoffLat = $request->dropoff_latitude;
            $dropoffLon = $request->dropoff_longitude;

            $distance = 0;
            $fareEstimate = $rider->fare_per_passenger * $request->passengers;

            if ($dropoffLat && $dropoffLon) {
                $distance = $this->distanceCalculator->haversineDistance(
                    $pickupLat,
                    $pickupLon,
                    $dropoffLat,
                    $dropoffLon
                );

                $fareCalculation = $this->distanceCalculator->calculateFareEstimate(
                    $distance,
                    30, // Estimated 30 minutes
                    $rider->fare_per_passenger
                );

                $fareEstimate = $fareCalculation['total_fare'];
            }

            // Create ride log entry
            $rideLog = RideLog::create([
                'user_id' => $user->id,
                'rider_id' => $riderId,
                'vehicle_id' => $rider->vehicle_id,
                'pickup_location_name' => $request->pickup_location_name,
                'pickup_lat' => $pickupLat,
                'pickup_lon' => $pickupLon,
                'pickup_address' => $request->pickup_address,
                'dropoff_location_name' => $request->dropoff_location_name,
                'dropoff_lat' => $dropoffLat,
                'dropoff_lon' => $dropoffLon,
                'dropoff_address' => $request->dropoff_address,
                'no_of_passengers' => $request->passengers,
                'fare_amount' => $fareEstimate,
                'status' => RideLog::STATUS_MATCHED,
                'firebase_session_id' => RideLog::generateFirebaseSessionId(),
                'estimated_pickup_time' => now()->addMinutes(10), // Default 10 minutes
            ]);

            // Create Firebase real-time session
            $firebaseSessionId = $this->realtimeService->createRideSession(
                $rideLog->id,
                [
                    'user_id' => $user->id,
                    'rider_id' => $riderId,
                    'pickup_lat' => $pickupLat,
                    'pickup_lon' => $pickupLon,
                    'dropoff_lat' => $dropoffLat,
                    'dropoff_lon' => $dropoffLon,
                    'passengers' => $request->passengers,
                    'fare_amount' => $fareEstimate,
                ]
            );

            if ($firebaseSessionId) {
                $rideLog->update(['firebase_session_id' => $firebaseSessionId]);
            }

            Log::info('Ride booked successfully', [
                'ride_id' => $rideLog->id,
                'user_id' => $user->id,
                'rider_id' => $riderId,
                'pickup' => [$pickupLat, $pickupLon],
                'dropoff' => $dropoffLat ? [$dropoffLat, $dropoffLon] : null,
                'passengers' => $request->passengers,
                'fare_estimate' => $fareEstimate
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Auto-rickshaw booked successfully',
                'data' => [
                    'ride' => [
                        'id' => $rideLog->id,
                        'status' => $rideLog->status,
                        'pickup_location' => [
                            'latitude' => $rideLog->pickup_lat,
                            'longitude' => $rideLog->pickup_lon,
                            'address' => $rideLog->pickup_address,
                        ],
                        'dropoff_location' => $dropoffLat ? [
                            'latitude' => $rideLog->dropoff_lat,
                            'longitude' => $rideLog->dropoff_lon,
                            'address' => $rideLog->dropoff_address,
                        ] : null,
                        'passengers' => $rideLog->no_of_passengers,
                        'fare_estimate' => $rideLog->fare_amount,
                        'estimated_pickup_time' => $rideLog->estimated_pickup_time,
                        'firebase_session_id' => $rideLog->firebase_session_id,
                        'created_at' => $rideLog->created_at,
                    ],
                    'rider' => [
                        'id' => $rider->id,
                        'full_name' => $rider->full_name,
                        'phone_number' => $rider->phone_number,
                        'average_rating' => $rider->average_rating,
                        'current_location' => $rider->current_location,
                    ],
                    'vehicle' => [
                        'registration_number' => $rider->vehicle->registration_number,
                        'color' => $rider->vehicle->color,
                        'display_name' => $rider->vehicle->display_name,
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to book ride', [
                'user_id' => $user->id,
                'rider_id' => $request->rider_id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to book auto-rickshaw',
            ], 500);
        }
    }

    /**
     * Track active ride
     */
    public function trackRide(Request $request, int $rideId): JsonResponse
    {
        try {
            $user = $request->user();
            $rideLog = RideLog::where('id', $rideId)
                ->where('user_id', $user->id)
                ->with(['rider.vehicle'])
                ->first();

            if (!$rideLog) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found',
                ], 404);
            }

            if (!$rideLog->isActive()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride is not active',
                    'data' => ['ride_status' => $rideLog->status],
                ], 409);
            }

            // Get real-time data from Firebase
            $firebaseData = $this->realtimeService->getRideSession($rideId);

            $trackingData = [
                'ride' => [
                    'id' => $rideLog->id,
                    'status' => $rideLog->status,
                    'pickup_location' => $rideLog->pickup_coordinates,
                    'dropoff_location' => $rideLog->dropoff_coordinates,
                    'estimated_pickup_time' => $rideLog->estimated_pickup_time,
                    'actual_pickup_time' => $rideLog->actual_pickup_time,
                    'time_until_pickup' => $rideLog->time_until_pickup,
                ],
                'rider' => [
                    'id' => $rideLog->rider->id,
                    'full_name' => $rideLog->rider->full_name,
                    'phone_number' => $rideLog->rider->phone_number,
                    'current_location' => $rideLog->rider->current_location,
                ],
                'vehicle' => [
                    'registration_number' => $rideLog->rider->vehicle->registration_number,
                    'color' => $rideLog->rider->vehicle->color,
                ],
                'real_time_data' => $firebaseData,
            ];

            return response()->json([
                'status' => 'success',
                'message' => 'Ride tracking data',
                'data' => $trackingData,
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get ride tracking data', [
                'ride_id' => $rideId,
                'user_id' => $request->user()->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get ride tracking information',
            ], 500);
        }
    }

    /**
     * Enrich rider data with calculations and real-time info
     */
    private function enrichRiderData(
        $nearbyRiders,
        $routeRiders,
        array $firebaseRiders,
        float $pickupLat,
        float $pickupLon,
        ?float $dropoffLat,
        ?float $dropoffLon,
        int $passengers
    ): array {
        // Combine all riders and remove duplicates
        $allRiders = $nearbyRiders->concat($routeRiders)->unique('id');

        // Create Firebase lookup
        $firebaseLookup = collect($firebaseRiders)->keyBy('rider_id');

        return $allRiders->map(function ($rider) use ($firebaseLookup, $pickupLat, $pickupLon, $dropoffLat, $dropoffLon, $passengers) {
            $riderId = $rider->id;
            $firebaseData = $firebaseLookup->get($riderId);

            // Use Firebase location if more recent, otherwise use database location
            $currentLocation = $firebaseData &&
                               $firebaseData['last_update'] > ($rider->location_updated_at?->timestamp * 1000)
                ? ['latitude' => $firebaseData['latitude'], 'longitude' => $firebaseData['longitude']]
                : $rider->current_location;

            // Calculate fare estimate
            $fareEstimate = $rider->fare_per_passenger * $passengers;
            if ($dropoffLat && $dropoffLon) {
                $distance = $this->distanceCalculator->haversineDistance(
                    $pickupLat, $pickupLon, $dropoffLat, $dropoffLon
                );
                $fareCalculation = $this->distanceCalculator->calculateFareEstimate(
                    $distance, 30, $rider->fare_per_passenger
                );
                $fareEstimate = $fareCalculation['total_fare'];
            }

            return [
                'id' => $rider->id,
                'full_name' => $rider->full_name,
                'phone_number' => $rider->phone_number,
                'average_rating' => $rider->average_rating,
                'total_rides' => $rider->total_rides,
                'fare_per_passenger' => $rider->fare_per_passenger,
                'distance_km' => $rider->distance_km ?? 0,
                'estimated_eta_minutes' => $rider->estimated_eta_minutes ?? 0,
                'current_location' => $currentLocation,
                'vehicle' => $rider->vehicle ?? (object) $rider->toArray(),
                'fare_estimate' => $fareEstimate,
                'is_real_time' => !is_null($firebaseData),
                'last_update' => $firebaseData['last_update'] ?? $rider->location_updated_at,
            ];
        })->sortBy('distance_km')->values()->toArray();
    }
}