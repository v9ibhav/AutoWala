<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Rider;
use App\Models\Ride;
use App\Services\Ride\RideDiscoveryService;
use App\Services\Firebase\RealtimeService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class RideController extends Controller
{
    protected RideDiscoveryService $rideDiscoveryService;
    protected RealtimeService $realtimeService;

    public function __construct(
        RideDiscoveryService $rideDiscoveryService,
        RealtimeService $realtimeService
    ) {
        $this->rideDiscoveryService = $rideDiscoveryService;
        $this->realtimeService = $realtimeService;
    }

    /**
     * Search for nearby available riders using PostGIS
     */
    public function searchNearby(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'latitude' => 'required|numeric|between:-90,90',
                'longitude' => 'required|numeric|between:-180,180',
                'radius' => 'integer|min:1000|max:10000', // 1km to 10km radius
                'pickup_address' => 'required|string|max:255',
                'destination_address' => 'required|string|max:255',
                'destination_latitude' => 'required|numeric|between:-90,90',
                'destination_longitude' => 'required|numeric|between:-180,180',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid input parameters',
                    'errors' => $validator->errors()
                ], 422);
            }

            $userLocation = [
                'latitude' => $request->latitude,
                'longitude' => $request->longitude
            ];

            $destination = [
                'latitude' => $request->destination_latitude,
                'longitude' => $request->destination_longitude
            ];

            $radius = $request->radius ?? 5000; // Default 5km

            // Find nearby riders using PostGIS
            $nearbyRiders = $this->rideDiscoveryService->findNearbyRiders(
                $userLocation,
                $radius,
                $destination
            );

            // Calculate estimated fare for the trip
            $estimatedFare = $this->rideDiscoveryService->calculateFare(
                $userLocation,
                $destination
            );

            Log::info('Ride search performed', [
                'user_id' => auth()->id(),
                'location' => $userLocation,
                'riders_found' => count($nearbyRiders),
                'estimated_fare' => $estimatedFare
            ]);

            return response()->json([
                'status' => 'success',
                'data' => [
                    'riders' => $nearbyRiders,
                    'estimated_fare' => $estimatedFare,
                    'search_radius' => $radius,
                    'timestamp' => now()->toISOString()
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Ride search failed', [
                'user_id' => auth()->id(),
                'error' => $e->getMessage(),
                'location' => $request->only(['latitude', 'longitude'])
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to search for nearby rides',
                'error' => app()->environment('local') ? $e->getMessage() : null
            ], 500);
        }
    }

    /**
     * Get detailed information about a specific rider
     */
    public function getRiderDetails(string $riderId): JsonResponse
    {
        try {
            $rider = Rider::with(['vehicle', 'route', 'ratings'])
                ->where('id', $riderId)
                ->where('is_online', true)
                ->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider not found or currently offline'
                ], 404);
            }

            $riderData = [
                'id' => $rider->id,
                'name' => $rider->name,
                'phone' => $rider->phone,
                'rating' => round($rider->ratings->avg('rating'), 1),
                'total_rides' => $rider->total_rides,
                'years_experience' => $rider->years_experience,
                'profile_photo' => $rider->profile_photo,
                'vehicle' => [
                    'number' => $rider->vehicle->registration_number,
                    'model' => $rider->vehicle->model,
                    'color' => $rider->vehicle->color,
                    'capacity' => $rider->vehicle->capacity,
                ],
                'current_location' => [
                    'latitude' => $rider->current_latitude,
                    'longitude' => $rider->current_longitude,
                    'last_updated' => $rider->last_location_update
                ],
                'route' => $rider->route ? [
                    'name' => $rider->route->name,
                    'description' => $rider->route->description,
                ] : null,
                'availability' => [
                    'is_online' => $rider->is_online,
                    'accepts_rides' => $rider->accepts_rides,
                    'estimated_arrival' => $this->rideDiscoveryService->calculateETA(
                        [$rider->current_latitude, $rider->current_longitude],
                        [request('pickup_latitude'), request('pickup_longitude')]
                    )
                ]
            ];

            return response()->json([
                'status' => 'success',
                'data' => $riderData
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to get rider details', [
                'rider_id' => $riderId,
                'user_id' => auth()->id(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to get rider details'
            ], 500);
        }
    }

    /**
     * Book a ride with a specific rider
     */
    public function bookRide(Request $request): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'rider_id' => 'required|exists:riders,id',
                'pickup_latitude' => 'required|numeric|between:-90,90',
                'pickup_longitude' => 'required|numeric|between:-180,180',
                'pickup_address' => 'required|string|max:255',
                'destination_latitude' => 'required|numeric|between:-90,90',
                'destination_longitude' => 'required|numeric|between:-180,180',
                'destination_address' => 'required|string|max:255',
                'passenger_count' => 'integer|min:1|max:3'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid booking parameters',
                    'errors' => $validator->errors()
                ], 422);
            }

            // Check if rider is available
            $rider = Rider::where('id', $request->rider_id)
                ->where('is_online', true)
                ->where('accepts_rides', true)
                ->first();

            if (!$rider) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Rider is not available for booking'
                ], 400);
            }

            // Check if user has any pending rides
            $pendingRide = Ride::where('user_id', auth()->id())
                ->whereIn('status', ['pending', 'accepted', 'in_transit'])
                ->first();

            if ($pendingRide) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'You already have a pending ride',
                    'ride_id' => $pendingRide->id
                ], 400);
            }

            // Calculate fare
            $fare = $this->rideDiscoveryService->calculateFare(
                [$request->pickup_latitude, $request->pickup_longitude],
                [$request->destination_latitude, $request->destination_longitude]
            );

            // Create ride booking
            $ride = Ride::create([
                'user_id' => auth()->id(),
                'rider_id' => $request->rider_id,
                'pickup_latitude' => $request->pickup_latitude,
                'pickup_longitude' => $request->pickup_longitude,
                'pickup_address' => $request->pickup_address,
                'destination_latitude' => $request->destination_latitude,
                'destination_longitude' => $request->destination_longitude,
                'destination_address' => $request->destination_address,
                'passenger_count' => $request->passenger_count ?? 1,
                'estimated_fare' => $fare['total'],
                'status' => 'pending',
                'booking_time' => now(),
            ]);

            // Notify rider via Firebase
            $this->realtimeService->notifyRideRequest($rider->id, $ride);

            Log::info('Ride booked successfully', [
                'ride_id' => $ride->id,
                'user_id' => auth()->id(),
                'rider_id' => $request->rider_id,
                'fare' => $fare
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Ride booked successfully! Waiting for rider confirmation.',
                'data' => [
                    'ride_id' => $ride->id,
                    'status' => 'pending',
                    'estimated_fare' => $fare,
                    'rider' => [
                        'id' => $rider->id,
                        'name' => $rider->name,
                        'phone' => $rider->phone,
                        'vehicle_number' => $rider->vehicle?->registration_number
                    ],
                    'estimated_arrival_time' => $this->rideDiscoveryService->calculateETA(
                        [$rider->current_latitude, $rider->current_longitude],
                        [$request->pickup_latitude, $request->pickup_longitude]
                    )
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Ride booking failed', [
                'user_id' => auth()->id(),
                'rider_id' => $request->rider_id ?? null,
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to book ride',
                'error' => app()->environment('local') ? $e->getMessage() : null
            ], 500);
        }
    }

    /**
     * Track an ongoing ride in real-time
     */
    public function trackRide(string $rideId): JsonResponse
    {
        try {
            $ride = Ride::with(['user', 'rider.vehicle'])
                ->where('id', $rideId)
                ->where(function($query) {
                    $query->where('user_id', auth()->id())
                          ->orWhere('rider_id', auth()->id());
                })
                ->first();

            if (!$ride) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found or access denied'
                ], 404);
            }

            // Get real-time location data from Firebase
            $liveLocation = $this->realtimeService->getRiderLocation($ride->rider_id);

            $trackingData = [
                'ride_id' => $ride->id,
                'status' => $ride->status,
                'user' => [
                    'id' => $ride->user->id,
                    'name' => $ride->user->name,
                    'phone' => $ride->user->phone
                ],
                'rider' => [
                    'id' => $ride->rider->id,
                    'name' => $ride->rider->name,
                    'phone' => $ride->rider->phone,
                    'vehicle_number' => $ride->rider->vehicle?->registration_number,
                    'current_location' => $liveLocation,
                ],
                'trip_details' => [
                    'pickup_address' => $ride->pickup_address,
                    'destination_address' => $ride->destination_address,
                    'pickup_location' => [
                        'latitude' => $ride->pickup_latitude,
                        'longitude' => $ride->pickup_longitude
                    ],
                    'destination_location' => [
                        'latitude' => $ride->destination_latitude,
                        'longitude' => $ride->destination_longitude
                    ],
                    'passenger_count' => $ride->passenger_count
                ],
                'timing' => [
                    'booking_time' => $ride->booking_time,
                    'pickup_time' => $ride->pickup_time,
                    'start_time' => $ride->start_time,
                    'end_time' => $ride->end_time,
                ],
                'fare' => [
                    'estimated' => $ride->estimated_fare,
                    'final' => $ride->final_fare
                ]
            ];

            if ($ride->status === 'accepted' || $ride->status === 'in_transit') {
                $trackingData['eta'] = $this->rideDiscoveryService->calculateETA(
                    [$liveLocation['latitude'], $liveLocation['longitude']],
                    [$ride->pickup_latitude, $ride->pickup_longitude]
                );
            }

            return response()->json([
                'status' => 'success',
                'data' => $trackingData
            ]);

        } catch (\Exception $e) {
            Log::error('Ride tracking failed', [
                'ride_id' => $rideId,
                'user_id' => auth()->id(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to track ride'
            ], 500);
        }
    }

    /**
     * Submit rating and feedback for completed ride
     */
    public function rateRide(Request $request, string $rideId): JsonResponse
    {
        try {
            $validator = Validator::make($request->all(), [
                'rating' => 'required|integer|min:1|max:5',
                'feedback' => 'nullable|string|max:500',
                'categories' => 'nullable|array',
                'categories.*' => 'string'
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Invalid rating parameters',
                    'errors' => $validator->errors()
                ], 422);
            }

            $ride = Ride::where('id', $rideId)
                ->where('user_id', auth()->id())
                ->where('status', 'completed')
                ->first();

            if (!$ride) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Ride not found, not completed, or access denied'
                ], 404);
            }

            // Check if already rated
            if ($ride->user_rating) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'This ride has already been rated'
                ], 400);
            }

            // Update ride with rating
            $ride->update([
                'user_rating' => $request->rating,
                'user_feedback' => $request->feedback,
                'rating_categories' => $request->categories,
                'rated_at' => now()
            ]);

            // Update rider's overall rating
            $this->rideDiscoveryService->updateRiderRating($ride->rider_id);

            Log::info('Ride rated successfully', [
                'ride_id' => $rideId,
                'user_id' => auth()->id(),
                'rider_id' => $ride->rider_id,
                'rating' => $request->rating
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Thank you for your feedback! Your rating has been submitted.',
                'data' => [
                    'ride_id' => $ride->id,
                    'rating' => $request->rating,
                    'feedback' => $request->feedback
                ]
            ]);

        } catch (\Exception $e) {
            Log::error('Ride rating failed', [
                'ride_id' => $rideId,
                'user_id' => auth()->id(),
                'error' => $e->getMessage()
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to submit rating'
            ], 500);
        }
    }
}