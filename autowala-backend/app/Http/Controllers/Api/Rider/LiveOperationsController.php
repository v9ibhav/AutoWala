<?php

namespace App\Http\Controllers\Api\Rider;

use App\Http\Controllers\Controller;
use App\Services\Location\GeospatialService;
use App\Services\Firebase\RealtimeService;
use App\Services\Auth\JWTService;
use App\Models\Rider;
use App\Models\User;
use App\Models\Vehicle;
use App\Models\Route;
use App\Models\RideLog;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class LiveOperationsController extends Controller
{
    protected GeospatialService $geospatialService;
    protected RealtimeService $realtimeService;
    protected JWTService $jwtService;

    public function __construct(
        GeospatialService $geospatialService,
        RealtimeService $realtimeService,
        JWTService $jwtService
    ) {
        $this->geospatialService = $geospatialService;
        $this->realtimeService = $realtimeService;
        $this->jwtService = $jwtService;
    }

    /**
     * Go online and start accepting rides
     */
    public function goOnline(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'route_ids' => 'nullable|array',
            'route_ids.*' => 'integer|exists:routes,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid location data',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rider profile not found',
            ], 404);
        }

        // Check KYC and vehicle status
        if ($rider->kyc_status !== 'verified') {
            return response()->json([
                'status' => 'error',
                'message' => 'KYC verification required',
                'data' => ['kyc_status' => $rider->kyc_status],
            ], 403);
        }

        $vehicle = $rider->vehicle;
        if (!$vehicle || !$vehicle->is_verified) {
            return response()->json([
                'status' => 'error',
                'message' => 'Vehicle verification required',
            ], 403);
        }

        $latitude = $request->latitude;
        $longitude = $request->longitude;

        // Validate coordinates are in India
        if (!$this->geospatialService->isLocationInIndia($latitude, $longitude)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Location must be within India',
            ], 422);
        }

        try {
            DB::transaction(function () use ($rider, $latitude, $longitude, $request) {
                // Update rider status and location
                $rider->updateLocation($latitude, $longitude);
                $rider->goOnline();

                // Validate and set active routes
                $routeIds = $request->route_ids ?? [];
                if (!empty($routeIds)) {
                    // Verify routes belong to this rider
                    $validRoutes = Route::where('rider_id', $rider->id)
                        ->whereIn('id', $routeIds)
                        ->where('is_active', true)
                        ->pluck('id')
                        ->toArray();

                    if (count($validRoutes) !== count($routeIds)) {
                        throw new \Exception('Invalid route IDs provided');
                    }

                    $routeIds = $validRoutes;
                }

                // Update Firebase with rider location and status
                $this->realtimeService->updateRiderLocation(
                    $rider->id,
                    $latitude,
                    $longitude,
                    null,
                    null,
                    [
                        'full_name' => $rider->full_name,
                        'phone_number' => $rider->phone_number,
                        'rating' => $rider->average_rating,
                        'fare_per_passenger' => $rider->fare_per_passenger,
                        'vehicle_number' => $vehicle->registration_number,
                        'vehicle_color' => $vehicle->color,
                        'max_passengers' => $vehicle->max_passengers,
                    ]
                );

                // Start rider session in Firebase
                $this->realtimeService->startRiderSession(
                    $rider->id,
                    [
                        'full_name' => $rider->full_name,
                        'phone_number' => $rider->phone_number,
                        'rating' => $rider->average_rating,
                        'fare_per_passenger' => $rider->fare_per_passenger,
                        'vehicle' => [
                            'registration_number' => $vehicle->registration_number,
                            'color' => $vehicle->color,
                            'make' => $vehicle->make,
                            'model' => $vehicle->model,
                        ],
                    ],
                    $routeIds
                );
            });

            Log::info('Rider went online', [
                'rider_id' => $rider->id,
                'location' => [$latitude, $longitude],
                'routes' => $request->route_ids ?? []
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'You are now online and accepting rides',
                'data' => [
                    'rider' => [
                        'id' => $rider->id,
                        'is_online' => true,
                        'current_location' => [
                            'latitude' => $latitude,
                            'longitude' => $longitude,
                        ],
                        'location_updated_at' => now(),
                        'active_routes' => $request->route_ids ?? [],
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to go online', [
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to go online: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Go offline
     */
    public function goOffline(Request $request): JsonResponse
    {
        $user = $request->user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rider profile not found',
            ], 404);
        }

        try {
            // Update rider status
            $rider->goOffline();

            // Remove from Firebase
            $this->realtimeService->removeRiderFromActive($rider->id);
            $this->realtimeService->endRiderSession($rider->id);

            Log::info('Rider went offline', ['rider_id' => $rider->id]);

            return response()->json([
                'status' => 'success',
                'message' => 'You are now offline',
                'data' => [
                    'rider' => [
                        'id' => $rider->id,
                        'is_online' => false,
                        'last_online_at' => now(),
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to go offline', [
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to go offline',
            ], 500);
        }
    }

    /**
     * Update rider location
     */
    public function updateLocation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'heading' => 'nullable|numeric|between:0,360',
            'accuracy' => 'nullable|numeric|min:0|max:1000',
            'speed' => 'nullable|numeric|min:0|max:200',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid location data',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rider = $user->rider;

        if (!$rider || !$rider->is_online) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rider not online',
            ], 409);
        }

        $latitude = $request->latitude;
        $longitude = $request->longitude;

        // Validate coordinates
        if (!$this->geospatialService->areValidCoordinates($latitude, $longitude) ||
            !$this->geospatialService->isLocationInIndia($latitude, $longitude)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid coordinates for Indian location',
            ], 422);
        }

        try {
            // Update database location
            $rider->updateLocation($latitude, $longitude, $request->heading);

            // Update Firebase real-time location
            $success = $this->realtimeService->updateRiderLocation(
                $rider->id,
                $latitude,
                $longitude,
                $request->heading,
                $request->accuracy
            );

            if (!$success) {
                Log::warning('Firebase location update failed, but database updated', [
                    'rider_id' => $rider->id,
                    'location' => [$latitude, $longitude]
                ]);
            }

            return response()->json([
                'status' => 'success',
                'message' => 'Location updated successfully',
                'data' => [
                    'rider_id' => $rider->id,
                    'location' => [
                        'latitude' => $latitude,
                        'longitude' => $longitude,
                        'heading' => $request->heading,
                        'accuracy' => $request->accuracy,
                    ],
                    'updated_at' => now(),
                    'firebase_updated' => $success,
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to update rider location', [
                'rider_id' => $rider->id,
                'location' => [$latitude, $longitude],
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update location',
            ], 500);
        }
    }

    /**
     * Get active rides for rider
     */
    public function getActiveRides(Request $request): JsonResponse
    {
        $user = $request->user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rider profile not found',
            ], 404);
        }

        try {
            $activeRides = RideLog::where('rider_id', $rider->id)
                ->whereIn('status', [RideLog::STATUS_MATCHED, RideLog::STATUS_IN_TRANSIT])
                ->with(['user'])
                ->orderBy('created_at', 'desc')
                ->get();

            $ridesData = $activeRides->map(function ($ride) {
                return [
                    'id' => $ride->id,
                    'status' => $ride->status,
                    'pickup_location' => [
                        'latitude' => $ride->pickup_lat,
                        'longitude' => $ride->pickup_lon,
                        'address' => $ride->pickup_address,
                    ],
                    'dropoff_location' => $ride->dropoff_lat ? [
                        'latitude' => $ride->dropoff_lat,
                        'longitude' => $ride->dropoff_lon,
                        'address' => $ride->dropoff_address,
                    ] : null,
                    'passengers' => $ride->no_of_passengers,
                    'fare_amount' => $ride->fare_amount,
                    'user' => [
                        'id' => $ride->user->id,
                        'full_name' => $ride->user->full_name,
                        'phone_number' => $ride->user->phone_number,
                    ],
                    'estimated_pickup_time' => $ride->estimated_pickup_time,
                    'created_at' => $ride->created_at,
                ];
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Active rides retrieved',
                'data' => [
                    'active_rides' => $ridesData,
                    'total_count' => $ridesData->count(),
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get active rides', [
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to retrieve active rides',
            ], 500);
        }
    }

    /**
     * Confirm passenger pickup
     */
    public function confirmPickup(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer|exists:ride_logs,id',
            'pickup_confirmed_at' => 'nullable|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid request data',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rider = $user->rider;
        $rideId = $request->ride_id;

        try {
            $rideLog = RideLog::where('id', $rideId)
                ->where('rider_id', $rider->id)
                ->where('status', RideLog::STATUS_MATCHED)
                ->first();

            if (!$rideLog) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found or cannot be started',
                ], 404);
            }

            // Start the ride
            $rideLog->startRide();

            // Update Firebase ride session
            $this->realtimeService->updateRideSession($rideId, [
                'status' => 'in_transit',
                'pickup_confirmed_at' => now()->timestamp * 1000,
                'actual_pickup_time' => now()->timestamp * 1000,
            ]);

            Log::info('Passenger pickup confirmed', [
                'ride_id' => $rideId,
                'rider_id' => $rider->id,
                'user_id' => $rideLog->user_id
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Passenger pickup confirmed',
                'data' => [
                    'ride' => [
                        'id' => $rideLog->id,
                        'status' => $rideLog->status,
                        'actual_pickup_time' => $rideLog->actual_pickup_time,
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to confirm pickup', [
                'ride_id' => $rideId,
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to confirm pickup',
            ], 500);
        }
    }

    /**
     * Complete ride
     */
    public function completeRide(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'ride_id' => 'required|integer|exists:ride_logs,id',
            'actual_distance_km' => 'nullable|numeric|min:0|max:100',
            'completion_notes' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid request data',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();
        $rider = $user->rider;
        $rideId = $request->ride_id;

        try {
            $rideLog = RideLog::where('id', $rideId)
                ->where('rider_id', $rider->id)
                ->where('status', RideLog::STATUS_IN_TRANSIT)
                ->first();

            if (!$rideLog) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found or cannot be completed',
                ], 404);
            }

            // Complete the ride
            $rideLog->completeRide($request->actual_distance_km);

            // Update Firebase ride session
            $this->realtimeService->updateRideSession($rideId, [
                'status' => 'completed',
                'completed_at' => now()->timestamp * 1000,
                'actual_distance_km' => $request->actual_distance_km,
            ]);

            // End Firebase ride session
            $this->realtimeService->endRideSession($rideId);

            // Update rider statistics
            $rider->updateRating();

            Log::info('Ride completed', [
                'ride_id' => $rideId,
                'rider_id' => $rider->id,
                'user_id' => $rideLog->user_id,
                'actual_distance_km' => $request->actual_distance_km
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Ride completed successfully',
                'data' => [
                    'ride' => [
                        'id' => $rideLog->id,
                        'status' => $rideLog->status,
                        'completed_at' => $rideLog->completed_at,
                        'actual_distance_km' => $rideLog->actual_distance_km,
                        'actual_duration_min' => $rideLog->actual_duration_min,
                        'fare_amount' => $rideLog->fare_amount,
                    ],
                ],
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to complete ride', [
                'ride_id' => $rideId,
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to complete ride',
            ], 500);
        }
    }

    /**
     * Get rider dashboard data
     */
    public function getDashboard(Request $request): JsonResponse
    {
        $user = $request->user();
        $rider = $user->rider;

        if (!$rider) {
            return response()->json([
                'status' => 'error',
                'message' => 'Rider profile not found',
            ], 404);
        }

        try {
            // Get today's stats
            $today = now()->startOfDay();
            $todayRides = RideLog::where('rider_id', $rider->id)
                ->where('created_at', '>=', $today)
                ->where('status', RideLog::STATUS_COMPLETED)
                ->get();

            $todayEarnings = $todayRides->sum('fare_amount');
            $todayRideCount = $todayRides->count();

            // Get recent ride history
            $recentRides = RideLog::where('rider_id', $rider->id)
                ->whereIn('status', [RideLog::STATUS_COMPLETED, RideLog::STATUS_CANCELLED])
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->with('user')
                ->get();

            $dashboardData = [
                'rider_status' => [
                    'is_online' => $rider->is_online,
                    'kyc_status' => $rider->kyc_status,
                    'average_rating' => $rider->average_rating,
                    'total_rides' => $rider->total_rides,
                    'location_updated_at' => $rider->location_updated_at,
                ],
                'today_stats' => [
                    'rides_completed' => $todayRideCount,
                    'earnings' => $todayEarnings,
                    'hours_online' => $rider->is_online ?
                        ($rider->last_online_at ? $rider->last_online_at->diffInHours(now()) : 0) : 0,
                ],
                'recent_rides' => $recentRides->map(function ($ride) {
                    return [
                        'id' => $ride->id,
                        'status' => $ride->status,
                        'passenger_name' => $ride->user->full_name,
                        'pickup_address' => $ride->pickup_address,
                        'dropoff_address' => $ride->dropoff_address,
                        'fare_amount' => $ride->fare_amount,
                        'completed_at' => $ride->completed_at,
                        'created_at' => $ride->created_at,
                    ];
                }),
            ];

            return response()->json([
                'status' => 'success',
                'message' => 'Dashboard data retrieved',
                'data' => $dashboardData,
                'meta' => [
                    'timestamp' => now()->toISOString(),
                    'version' => '1.0',
                ],
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get rider dashboard', [
                'rider_id' => $rider->id,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to retrieve dashboard data',
            ], 500);
        }
    }
}